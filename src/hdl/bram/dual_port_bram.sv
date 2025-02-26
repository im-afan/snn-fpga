/* PASSED TESTS */

/*
 * FOR SIMULATION USE ONLY
 * USE BLOCK MEMORY GENERATOR IN DEPLOYMENT
 * True dual-port RAM
 */

`ifndef DUAL_PORT_BRAM
`define DUAL_PORT_BRAM

module dual_port_bram #(
    parameter DATA_WIDTH_A,
    parameter DATA_WIDTH_B,
    parameter ADDR_WIDTH_A,
    parameter ADDR_WIDTH_B,
    parameter MEM_PATH,
    parameter integer DEPTH = 1024
)(
    clka, addra, dina, douta, wea, ena,
    clkb, addrb, dinb, doutb, web, enb 
);
    localparam BRAM_DATA_WIDTH = DATA_WIDTH_A;
    localparam BRAM_ADDR_WIDTH = ADDR_WIDTH_A;

    input wire clka;
    // Port A signals
    input wire [BRAM_ADDR_WIDTH-1:0] addra;
    input wire [BRAM_DATA_WIDTH-1:0] dina;
    output reg [BRAM_DATA_WIDTH-1:0] douta;
    input wire [BRAM_DATA_WIDTH/8-1:0] wea; // Byte-enable for write
    input wire ena;
    
    // Port B signals
    input wire clkb;
    input wire [BRAM_ADDR_WIDTH-1:0] addrb;
    input wire [BRAM_DATA_WIDTH-1:0] dinb;
    output reg [BRAM_DATA_WIDTH-1:0] doutb;
    input wire [BRAM_DATA_WIDTH/8-1:0] web; // Byte-enable for write
    input wire enb;

    localparam BASE_PATH = "/Users/andrew/Desktop/snn-fpga/src/hdl/bram/mem/mlp/";

    localparam LOG_WORD_WIDTH = $clog2(BRAM_DATA_WIDTH / 8);
    // BRAM memory declaration
    reg [BRAM_DATA_WIDTH-1:0] mem [DEPTH-1:0];

    initial begin
        for(integer asdf = 0; asdf < DEPTH; asdf++) begin
            mem[asdf] = 0;
        end
        $display("reading %s", {BASE_PATH, MEM_PATH});
        $readmemb({BASE_PATH, MEM_PATH}, mem);
    end

    integer i;

    // Port A: Read and Masked Write
    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra >> LOG_WORD_WIDTH]; // Read data
            for (i = 0; i < BRAM_DATA_WIDTH/8; i = i + 1) begin
                if (wea[i]) begin
                    mem[addra >> LOG_WORD_WIDTH][i*8 +: 8] <= dina[i*8 +: 8];
                end
            end
        end
    end

    // Port B: Read and Masked Write
    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb >> LOG_WORD_WIDTH]; // Read data
            for (i = 0; i < BRAM_DATA_WIDTH/8; i = i + 1) begin
                if (web[i]) begin
                    mem[addrb >> LOG_WORD_WIDTH][i*8 +: 8] <= dinb[i*8 +: 8];
                end
            end
        end
    end

endmodule

`endif