module buff_idx_controller# (
    parameter integer MAX_NEURONS,
    parameter integer CROSSBAR_NEURONS
) (
    input wire clk,
    input wire en, 
    input wire [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] has_spk_nxt,
    output reg buff_idx,
    output reg [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] has_spk
);
    reg flipped = 0;
    initial buff_idx = 0;

    always @(posedge clk) begin
        if(~en && ~flipped) begin
            buff_idx <= ~buff_idx;
            has_spk <= has_spk_nxt;
            flipped <= 1;
        end
        else if(en) begin
            flipped <= 0;
        end
    end
endmodule