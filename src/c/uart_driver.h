#include "xuartlite.h"
#include "snn_driver.h"
#include "xparameters.h"

#define UART_BASE_ADDR XPAR_AXI_UARTLITE_1_BASEADDR

XUartLite uart;
u8 op[8];
u8 send[4];
/*
 * OPCODE TABLE
 * 0: write_tile_idx
 * 1: write_weight
 * 2: write_input
 * 3: read_tile_idx_x
 * 4: read_tile_idx_y
 * 5: read_weight
 * 6: read_input
 * 7: read_spk_out
 * 8: do timestep
 * 9: reset parameters
*/


void setup_uart() {
    int status = XUartLite_Initialize(&uart, UART_BASE_ADDR);
    if(status != XST_SUCCESS) xil_printf("init uart fail\n\r");
}

void write(u32 x) {
    for(int i = 0; i < 4; i++) {
        send[i] = (x % (1 << (8*i+8))) >> (8*i);
        //if(x) xil_printf("send[%d] = %d\n\r", i, send[i]);
    }
    XUartLite_Send(&uart, send, 4);
    while(XUartLite_IsSending(&uart));
}

void listen() {
    u8 idx;
    idx = 0;

    while(idx < 8) {
        idx += XUartLite_Recv(&uart, op + idx, 8 - idx);
    }

    if(op[0] == 0) write_tile((op[1] << 8) | op[2], (op[3] << 8) | op[4], (op[5] << 8) | op[6]), write(0);
    if(op[0] == 1) write_weight((op[1] << 8) | op[2], op[3], op[4], op[5]), write(0);
    if(op[0] == 2) write_network_input((op[1] << 8) | op[2], op[3]), write(0);
    if(op[0] == 3) write(read_tile_idx_x((op[1] << 8) | op[2]));
    if(op[0] == 4) write(read_tile_idx_y((op[1] << 8) | op[2]));
    if(op[0] == 5) write(read_weight((op[1] << 8) | op[2], op[3], op[4]));
    if(op[0] == 6) write(read_network_input((op[1] << 8) | op[2]));
    if(op[0] == 7) write(read_spk_out((op[1] << 8) | op[2]));
    if(op[0] == 8) timestep(), write(0);
    if(op[0] == 9) reset_model(), write(0);
}