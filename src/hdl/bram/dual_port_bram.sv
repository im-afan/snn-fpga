/* PASSED TESTS */

/*
 * FOR SIMULATION USE ONLY
 * USE BLOCK MEMORY GENERATOR IN DEPLOYMENT
 * True dual-port RAM
 */

module dual_port_bram #(
    parameter BRAM_DATA_WIDTH,
    parameter BRAM_ADDR_WIDTH
)(
    input wire clka,
    // Port A signals
    input wire [BRAM_ADDR_WIDTH-1:0] addra,
    input wire [BRAM_DATA_WIDTH-1:0] dina,
    output reg [BRAM_DATA_WIDTH-1:0] douta,
    input wire [BRAM_DATA_WIDTH/8-1:0] wea, // Byte-enable for write
    input wire ena,
    
    // Port B signals
    input wire clkb,
    input wire [BRAM_ADDR_WIDTH-1:0] addrb,
    input wire [BRAM_DATA_WIDTH-1:0] dinb,
    output reg [BRAM_DATA_WIDTH-1:0] doutb,
    input wire [BRAM_DATA_WIDTH/8-1:0] web, // Byte-enable for write
    input wire enb
);

    localparam LOG_WORD_WIDTH = $clog2(BRAM_DATA_WIDTH / 8);
    // BRAM memory declaration
    reg [BRAM_DATA_WIDTH-1:0] mem [1023:0];

    initial begin
        for(integer asdf = 0; asdf < 1024; asdf++) begin
            mem[asdf] = 0;
        end
        $readmemb("/home/andrew/Desktop/snn-soc/src/hdl/bram/bram.mem", mem);
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


/*module dual_port_bram#(
    parameter integer BRAM_DATA_WIDTH,
    parameter integer BRAM_ADDR_WIDTH
) (
    input wire clka,
    input wire ena,
    input wire [BRAM_DATA_WIDTH/8-1:0] wea,
    input wire [BRAM_ADDR_WIDTH-1:0] addra,
    input wire [BRAM_DATA_WIDTH-1:0] dina,
    output reg [BRAM_DATA_WIDTH-1:0] douta,

    input wire clkb,
    input wire enb,
    input wire [BRAM_DATA_WIDTH/8-1:0] web,
    input wire [BRAM_ADDR_WIDTH-1:0] addrb,
    input wire [BRAM_DATA_WIDTH-1:0] dinb,
    output reg [BRAM_DATA_WIDTH-1:0] doutb
);
    localparam LOG_WORD_WIDTH = $clog2(BRAM_DATA_WIDTH / 8);
    localparam LOG_BYTE_WIDTH = 7;

    reg [BRAM_DATA_WIDTH-1:0] memory[1024];

    initial begin
        for(integer asdf = 0; asdf < 1024; asdf++) begin
            memory[asdf] = 0;
        end
        $readmemb("bram.mem", memory);
    end

    always @(posedge clka) begin
        if(ena) begin
            if(|wea) begin
                memory[addra >>> LOG_BYTE_WIDTH] <= dina;
            end
            douta <= memory[addra >>> LOG_BYTE_WIDTH];
        end
    end

    always @(posedge clkb) begin
        if(enb) begin
            if(|web) begin
                memory[addrb >>> LOG_BYTE_WIDTH] <= dinb;
            end
            doutb <= memory[addrb >>> LOG_BYTE_WIDTH];
        end
    end
endmodule*/