#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"

#ifndef SNN_DRIVER
#define SNN_DRIVER

const u32 CROSSBAR_NEURONS = 16;

const u32 BASE_ADDR_WEIGHT = XPAR_AXI_BRAM_CTRL_0_BASEADDR;
const u32 BASE_ADDR_SPK = XPAR_AXI_BRAM_CTRL_1_BASEADDR;
const u32 BASE_ADDR_INPUT = XPAR_AXI_BRAM_CTRL_2_BASEADDR;
const u32 BASE_ADDR_TILE_IDX = XPAR_AXI_BRAM_CTRL_3_BASEADDR;

void write_tile(u32 tile_idx, u16 x, u16 y) {
    xil_printf("write_tile idx %d = %d %d\n\r", tile_idx, x, y);
	Xil_Out16(BASE_ADDR_TILE_IDX + 2*tile_idx, x);
    Xil_Out16(BASE_ADDR_TILE_IDX + 2*tile_idx + 1, y);
}

void write_weight(u32 tile_idx, u32 x, u32 y, u8 val) {
	Xil_Out8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS*tile_idx + x * CROSSBAR_NEURONS + y, val);
}

void write_network_input(u32 x, u8 val) {
	Xil_Out8(BASE_ADDR_INPUT + x, val);
}

u16 read_spk_out(u32 x) {
	return Xil_In16(BASE_ADDR_SPK + x);
}

/*
void timestep(int timeout) {
	write_enable(0);
	usleep(timeout); // maybe include a done signal instead
	write_enable(1);
	usleep(timeout); // maybe include a done signal instead
}

void reset_network() {
	for(int i = 0; i < MAX_NEURONS; i++) {
		write_network_input(i, 0);
		write_mem(i, 0);
	}
}*/
#endif
