/*
Most priority to least priority:
0 = highest 3 = lowest
*/

module bram_switcher #(
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer BRAM_DATA_WIDTH
) (
    input wire clk[3:0],
    input wire en[3:0],
    input wire [BRAM_ADDR_WIDTH-1:0] addr[3:0],
    input wire [BRAM_DATA_WIDTH/8-1:0] we[3:0],
    input wire [BRAM_DATA_WIDTH-1:0] din[3:0],
    output wire [BRAM_DATA_WIDTH-1:0] dout[3:0],
    output wire active [3:0],

    output wire clka,
    output wire ena,
    output wire [BRAM_ADDR_WIDTH-1:0] addra,
    output wire [BRAM_DATA_WIDTH/8-1:0] wea,
    output wire [BRAM_DATA_WIDTH-1:0] dina,
    input wire [BRAM_DATA_WIDTH-1:0] douta,

    output wire clkb,
    output wire enb,
    output wire [BRAM_ADDR_WIDTH-1:0] addrb,
    output wire [BRAM_DATA_WIDTH/8-1:0] web,
    output wire [BRAM_DATA_WIDTH-1:0] dinb,
    input wire [BRAM_DATA_WIDTH-1:0] doutb
); 
    wire a_used, b_used;

    always @(*) begin
        a_used = 0;
        b_used = 0; 
        for(integer i = 0; i < 4; i++) begin
            if(en[i]) begin
                if(a_used) begin
                    clka = clk[i];
                    ena = en[i];
                    addra = addr[i];
                    wea = we[i];
                    dina = din[i];
                    dout[i] = douta;
                    active[i] = 1;
                    a_used = 1;
                end else if(b_used) begin
                    clkb = clk[i];
                    enb = en[i];
                    addrb = addr[i];
                    web = we[i];
                    dinb = din[i];
                    dout[i] = doutb;
                    active[i] = 1;
                    b_used = 1;
                end else begin
                    active[i] = 0;
                end
            end
        end
    end
endmodule