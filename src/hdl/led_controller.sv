module led_controller (
    input wire clk,
    input wire en,
    input wire [15:0] spk_out,
    output reg [15:0] led
);
    always @(posedge clk) begin
        if(~en) begin
            led <= 0;
        end else begin
            led <= (led | spk_out);
        end
    end
endmodule  