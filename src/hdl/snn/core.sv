module core # (
    parameter integer NETWORK_WIDTH,
    parameter integer MOD 
) (
    input wire clk,
    input wire en,
    input wire [15:0] idx,
    input wire [15:0] x,
    input wire [15:0] y,
    input wire spk_in,
    output reg push,
    output wire tile_idx_y,
    output wire [127:0] weight
);
    reg bram_en;
    reg [15:0] weight_addr;
    reg spk_in1;
    assign weight_addr = idx * 16;
    assign tile_idx_y = y;

    single_port_bram #(
        .BRAM_DATA_WIDTH(127),
        .BRAM_ADDR_WIDTH(16),
        .MEM_PATH({"weight_mem", MOD, ".mem"})
    ) bram (
        .clk(clk),
        .en(bram_en),
        .addr(weight_addr),
        .din(0),
        .dout(weight),
        .we(0)
    );

    always @(posedge clk) begin
        if(~en) begin
            bram_en <= 0;
            push <= 0;
        end else begin
            if(spk_in) begin
                bram_en <= 1;
                push <= spk_in1;
            end
            spk_in1 <= spk_in;
        end
    end

endmodule