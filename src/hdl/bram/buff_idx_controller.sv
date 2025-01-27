module buff_idx_controller (
    input wire clk,
    input wire en, 
    output reg buff_idx
);
    reg flipped = 0;
    initial buff_idx = 1;

    always @(posedge clk) begin
        if(~en && ~flipped) begin
            buff_idx <= ~buff_idx;
            flipped <= 1;
        end
        else if(en) begin
            flipped <= 0;
        end
    end
endmodule