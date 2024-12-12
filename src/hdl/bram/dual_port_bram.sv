module dual_port_bram#(
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
                memory[addra >>> LOG_WORD_WIDTH] <= dina;
            end
            douta <= memory[addra >>> LOG_WORD_WIDTH];
        end
    end

    always @(posedge clkb) begin
        if(enb) begin
            if(|web) begin
                memory[addrb >>> LOG_WORD_WIDTH] <= dinb;
            end
            doutb <= memory[addrb >>> LOG_WORD_WIDTH];
        end
    end
endmodule