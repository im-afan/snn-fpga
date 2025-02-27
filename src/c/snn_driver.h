#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xgpio.h"

#ifndef SNN_DRIVER
#define SNN_DRIVER

const u32 CROSSBAR_NEURONS = 16;
const u32 MAX_NEURONS = 1024;
const u32 MAX_TILES = 512;

const u32 BASE_ADDR_WEIGHT = XPAR_AXI_BRAM_CTRL_0_BASEADDR;
const u32 BASE_ADDR_SPK = XPAR_AXI_BRAM_CTRL_1_BASEADDR;
const u32 BASE_ADDR_INPUT = XPAR_AXI_BRAM_CTRL_2_BASEADDR; // direct current input
const u32 BASE_ADDR_TILE_IDX = XPAR_AXI_BRAM_CTRL_3_BASEADDR;
//const u32 BASE_ADDR_SPK_IN = XPAR_AXI_BRAM_CTRL_4_BASEADDR; // spiking input

const u32 BASE_ADDR_EN = XPAR_AXI_GPIO_0_BASEADDR;

const u32 SNN_STATUS_CHANNEL = 1;
const u32 SNN_EN_CHANNEL = 2;

XGpio gpio;

void write_tile(u16 tile_idx, u16 x, u16 y, u8 x_ext, u8 y_ext) {
    //xil_printf("write_tile_idx %d\n\r", tile_idx);
	Xil_Out16(BASE_ADDR_TILE_IDX + 4*2*tile_idx, x);
    Xil_Out16(BASE_ADDR_TILE_IDX + 4*2*tile_idx + 2, y);
    Xil_Out16(BASE_ADDR_TILE_IDX + 4*2*tile_idx + 4, x_ext);
    Xil_Out16(BASE_ADDR_TILE_IDX + 4*2*tile_idx + 6, y_ext);
}

void write_weight(u16 tile_idx, u8 x, u8 y, s8 val) {
	Xil_Out8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS*tile_idx + x * CROSSBAR_NEURONS + y, (u8)val);
}

void write_network_input(u16 x, s8 val) {
	Xil_Out8(BASE_ADDR_INPUT + x, (u8)val);
}


s8 read_network_input(u32 x) {
    return (s8) Xil_In8(BASE_ADDR_INPUT + x);
}

u16 read_spk_out(u16 x, u16 t) {
	return Xil_In16(BASE_ADDR_SPK + 2*(x + 8*t));
}

u16 read_tile_idx_x(u16 tile_idx) {
    return Xil_In16(BASE_ADDR_TILE_IDX + 4*tile_idx);
}

u16 read_tile_idx_y(u16 tile_idx) {
    return Xil_In16(BASE_ADDR_TILE_IDX + 4*tile_idx + 2);
}

s8 read_weight(u32 tile_idx, u32 x, u32 y) {
    return (s8) Xil_In8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS * tile_idx + x*CROSSBAR_NEURONS + y);
}

void setup_snn() {
    XGpio_Initialize(&gpio, BASE_ADDR_EN);
	XGpio_SetDataDirection(&gpio, SNN_EN_CHANNEL, 0x0);
	XGpio_SetDataDirection(&gpio, SNN_STATUS_CHANNEL, 0x3);
}

void snn_enable() {
	XGpio_DiscreteWrite(&gpio, SNN_EN_CHANNEL, 0x1);	
}

void snn_disable() {
	XGpio_DiscreteWrite(&gpio, SNN_EN_CHANNEL, 0x0);
}

int snn_done() {
	return (XGpio_DiscreteRead(&gpio, SNN_STATUS_CHANNEL) & 1);
}

int snn_ready() {
	return (XGpio_DiscreteRead(&gpio, SNN_STATUS_CHANNEL) & 2);
}

void timestep() {
	snn_enable();
    usleep(1024);
    snn_disable();
}

void reset_model() {
    for(int i = 0; i < MAX_TILES; i++) {
        for(int j = 0; j < CROSSBAR_NEURONS; j++) {
            for(int k = 0; k < CROSSBAR_NEURONS; k++){
                write_weight(i, j, k, 0);
            }
        }
        write_tile(i, 0, 0, 0, 0);
    }
    for(int i = 0; i < 1024*16; i++) {
        //xil_printf("resetting idx %d\n\r", i);
        write_network_input(i, 0);
    }
}

void dump_model(int i) {
    for(int j = 0; j < CROSSBAR_NEURONS; j++) {
        for(int k = 0; k < CROSSBAR_NEURONS; k++) {
            xil_printf("%d ", read_weight(i, j, k));
        }
        xil_printf("\n\r");
    }
}

#endif