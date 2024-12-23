/* PASSED TESTS */

/*
 * FOR SIMULATION USE ONLY
 * USE BLOCK MEMORY GENERATOR IN DEPLOYMENT
 * True dual-port RAM
 */

module simple_dual_port_bram #(
    parameter BRAM_DATA_WIDTH,
    parameter BRAM_ADDR_WIDTH,
    parameter MEM_PATH
)(

    // Port A signals (read only)
    input wire clka,
    input wire [BRAM_ADDR_WIDTH-1:0] addra,
    output reg [BRAM_DATA_WIDTH-1:0] douta,
    input wire ena,
    
    // Port B signals (write only)
    input wire clkb,
    input wire [BRAM_ADDR_WIDTH-1:0] addrb,
    input wire [BRAM_DATA_WIDTH-1:0] dinb,
    input wire [BRAM_DATA_WIDTH/8-1:0] web, // Byte-enable for write
    input wire enb
);

    localparam BASE_PATH = "C:/Users/andre/Desktop/snn-fpga/src/hdl/bram/mem/";

    localparam LOG_WORD_WIDTH = $clog2(BRAM_DATA_WIDTH / 8);
    // BRAM memory declaration
    reg [BRAM_DATA_WIDTH-1:0] mem [256:0];

    initial begin
        for(integer asdf = 0; asdf < 1024; asdf++) begin
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
        end
    end

    // Port B: Read and Masked Write
    always @(posedge clkb) begin
        if (enb) begin
            for (i = 0; i < BRAM_DATA_WIDTH/8; i = i + 1) begin
                if (web[i]) begin
                    mem[addrb >> LOG_WORD_WIDTH][i*8 +: 8] <= dinb[i*8 +: 8];
                end
            end
        end
    end

endmodule