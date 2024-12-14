`include "snn/lif.sv"
//`include "lif.sv"

/* TODO UNTESTED */

module lif_array #(
    parameter integer CROSSBAR_NEURONS, 
    parameter integer THRESH,
    parameter integer NETWORK_WIDTH
) (
    input wire clk,
    input wire enable,

    input wire bram_done,

    input wire [CROSSBAR_NEURONS-1:0] spk_in,
    input wire [NETWORK_WIDTH-1:0] u_mem_in [CROSSBAR_NEURONS],
    input wire [NETWORK_WIDTH-1:0] u_mac_out [CROSSBAR_NEURONS],

    output reg [CROSSBAR_NEURONS-1:0] spk_out,
    output reg [NETWORK_WIDTH-1:0] u_mem_out [CROSSBAR_NEURONS],
    output reg done,
    output reg bram_we,
    output reg bram_enable
);
    wire signed [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
    wire signed [NETWORK_WIDTH-1:0] mac_out [CROSSBAR_NEURONS];
    reg signed [NETWORK_WIDTH-1:0] mem_out[CROSSBAR_NEURONS];

    generate
        genvar i;
        for(i = 0 ; i < CROSSBAR_NEURONS; i++) begin
            assign mem_in[i] = signed'(u_mem_in[i]);
            assign mac_out[i] = signed'(u_mac_out[i]);
            assign u_mem_out[i] = unsigned'(mem_out[i]);
            wire [NETWORK_WIDTH-1:0] mac_out_debug;
            wire [NETWORK_WIDTH-1:0] mem_in_debug;
            wire [NETWORK_WIDTH-1:0] mem_out_debug;
            assign mac_out_debug = mac_out[i];
            assign mem_in_debug = mem_in[i];
            assign mem_out_debug = mem_out[i];
        end
    endgenerate

    localparam READ = 0;
    localparam LIF = 1;
    localparam WRITE = 2;

    reg [3:0] step;

    reg lif_enable;
    wire [CROSSBAR_NEURONS-1:0] lif_done;
    wire all_lif_done;
    assign all_lif_done = lif_done;

    generate
        //genvar i;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            lif #(
                .THRESH(THRESH),
                .NETWORK_WIDTH(NETWORK_WIDTH)
            ) neuron (
                .clk(clk),
                .enable(lif_enable),
                .spk_in(spk_in[i]),
                .mac_out(mac_out[i]),
                .mem_in(mem_in[i]),
                .spk_out(spk_out[i]),
                .mem_out(mem_out[i]),
                .done(lif_done[i])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if(~enable) begin
            step <= READ;
            lif_enable <= 0;
            done <= 0;
            bram_we <= 0;
            bram_enable <= 0;
        end else begin
            if(~done) begin
                case(step)
                    READ: begin
                        if(~bram_enable) begin
                            bram_we <= 0;
                            bram_enable <= 1;
                        end 
                        if(bram_done) begin
                            step <= LIF;
                            bram_enable <= 0;
                        end
                    end
                    LIF: begin
                        if(~lif_enable) begin
                            lif_enable <= 1;
                        end
                        if(all_lif_done) begin
                            lif_enable <= 0;
                            step <= WRITE;
                        end
                    end
                    WRITE: begin
                        if(~bram_enable) begin
                            bram_we <= 1;
                            bram_enable <= 1;
                        end
                        if(bram_done) begin
                            done <= 1;
                            step <= READ;
                            bram_enable <= 0;
                        end
                    end
                endcase
            end
        end
    end
endmodule