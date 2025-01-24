module single_port_switcher #(
    parameter integer ADDR_WIDTH,
    parameter integer DATA_WIDTH
) (
    input wire clka,               // Clock for port A
    input wire ena,
    input wire [DATA_WIDTH/8-1:0] wea, // Write mask enable for port A (1 bit per byte)
    input wire [ADDR_WIDTH-1:0] addra,  // Byte address for port A
    input wire [DATA_WIDTH-1:0] dina,   // Data input for port A
    output reg [DATA_WIDTH-1:0] douta,  // Data output for port A

    input wire clkb,               // Clock for port B
    input wire enb,
    input wire [DATA_WIDTH/8-1:0] web, // Write mask enable for port B (1 bit per byte)
    input wire [ADDR_WIDTH-1:0] addrb,  // Byte address for port B
    input wire [DATA_WIDTH-1:0] dinb,   // Data input for port B
    output reg [DATA_WIDTH-1:0] doutb   // Data output for port B
);

endmodule