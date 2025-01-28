module fifo #(
    parameter integer WIDTH,
    parameter integer LENGTH, 
    parameter integer INIT_DIFF = 0
) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    input wire push,
    input wire pop,

    output wire empty,
    output wire full,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] fifo [LENGTH];
    reg [7:0] read_ptr, write_ptr, diff;

    assign empty = (diff == 0);
    assign full = (diff == LENGTH-1);
    assign dout = fifo[read_ptr];

    always @(posedge clk) begin
        if(rst) begin
            read_ptr <= 0;
            write_ptr <= INIT_DIFF;
            diff <= INIT_DIFF;
            for(integer i = 0; i < LENGTH; i++)
                fifo[i] <= 0;
        end else begin
            if(push) begin
                diff <= diff + 1;
                write_ptr <= (write_ptr + 1) % LENGTH;
                fifo[write_ptr] <= din;
            end

            if(pop) begin
                diff <= diff - 1;
                fifo[read_ptr] <= 0;
                read_ptr <= (read_ptr + 1) % LENGTH;
            end
        end
    end
endmodule
