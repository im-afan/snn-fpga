
module asymmetric_dual_port_bram #(
    parameter ADDR_WIDTH_A = 16, 
    parameter DATA_WIDTH_A = 1024, 
    parameter ADDR_WIDTH_B = 16,
    parameter DATA_WIDTH_B = 32,
    parameter MEM_PATH = "weight_bram.mem"
)(
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
    localparam DEPTH_A = 256;

    (* ram_style = "block" *) reg [DATA_WIDTH_A-1:0] mem [0:DEPTH_A-1];

    initial begin
        for (integer i = 0; i < DEPTH_A; i++) begin
            mem[i] = 0;    
        end    
        $display("reading %s", {BASE_PATH, MEM_PATH});
        $readmemb({BASE_PATH, MEM_PATH}, mem);
    end

    wire [ADDR_WIDTH_A - $clog2(DATA_WIDTH_A / 8) - 1:0] word_addr_a = addra >> $clog2(DATA_WIDTH_A / 8);
    wire [ADDR_WIDTH_B - $clog2(DATA_WIDTH_A / 8) - 1:0] word_addr_b = addrb >> $clog2(DATA_WIDTH_A / 8);
    wire [$clog2(DATA_WIDTH_A / 8) - 1:0] byte_offset_b;
    assign byte_offset_b = addrb % (DATA_WIDTH_A / 8);

    always @(posedge clka) begin
        integer i;
        if (ena) begin
            for (i = 0; i < DATA_WIDTH_A / 8; i = i + 1) begin
                if (wea[i]) begin
                    mem[word_addr_a][i*8 +: 8] <= dina[i*8 +: 8];
                end
            end
            douta <= mem[word_addr_a];
        end
    end

    always @(posedge clkb) begin
        integer i;
        if (enb) begin
            for (i = 0; i < DATA_WIDTH_B / 8; i = i + 1) begin
                if (web[i]) begin
                    mem[word_addr_b][(byte_offset_b + i) * 8 +: 8] <= dinb[i*8 +: 8];
                end
            end
            doutb <= mem[word_addr_b][(byte_offset_b) * 8 +: DATA_WIDTH_B];
        end
    end
endmodule
