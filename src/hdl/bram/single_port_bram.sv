`ifndef single_PORT_BRAM
`define single_PORT_BRAM

module single_port_bram #(
    parameter integer BRAM_DATA_WIDTH,
    parameter integer BRAM_ADDR_WIDTH,
    parameter MEM_PATH
)(
    clk, addr, din, dout, we, en
);

    input wire clk;
    // Port A signals
    input wire [BRAM_ADDR_WIDTH-1:0] addr;
    input wire [BRAM_DATA_WIDTH-1:0] din;
    output reg [BRAM_DATA_WIDTH-1:0] dout;
    input wire [BRAM_DATA_WIDTH/8-1:0] we; // Byte-enable for write
    input wire en;
       
    localparam BASE_PATH = "/Users/andrew/Desktop/snn-fpga/src/hdl/bram/mem/";

    localparam LOG_WORD_WIDTH = $clog2(BRAM_DATA_WIDTH / 8);
    // BRAM memory declaration
    reg [BRAM_DATA_WIDTH-1:0] mem [1023:0];

    initial begin
        for(integer asdf = 0; asdf < 1024; asdf++) begin
            mem[asdf] = 0;
        end
        $display("reading %s", {BASE_PATH, MEM_PATH});
        $readmemb({BASE_PATH, MEM_PATH}, mem);
    end

    integer i;

    // Port A: Read and Masked Write
    always @(posedge clk) begin
        if (en) begin
            dout <= mem[addr >> LOG_WORD_WIDTH]; // Read data
            for (i = 0; i < BRAM_DATA_WIDTH/8; i = i + 1) begin
                if (we[i]) begin
                    mem[addr >> LOG_WORD_WIDTH][i*8 +: 8] <= din[i*8 +: 8];
                end
            end
        end
    end

endmodule

`endif