#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xgpio.h"

#ifndef SNN_DRIVER
#define SNN_DRIVER

const u32 CROSSBAR_NEURONS = 16;
const u32 MAX_NEURONS = 1024;
const u32 MAX_TILES = 256;

const u32 BASE_ADDR_WEIGHT = XPAR_AXI_BRAM_CTRL_0_BASEADDR;
const u32 BASE_ADDR_SPK = XPAR_AXI_BRAM_CTRL_1_BASEADDR;
const u32 BASE_ADDR_INPUT = XPAR_AXI_BRAM_CTRL_2_BASEADDR;
const u32 BASE_ADDR_TILE_IDX = XPAR_AXI_BRAM_CTRL_3_BASEADDR;

const u32 BASE_ADDR_EN = XPAR_AXI_GPIO_0_BASEADDR;

const u32 SNN_STATUS_CHANNEL = 1;
const u32 SNN_EN_CHANNEL = 2;

XGpio gpio;

void write_tile(u32 tile_idx, u16 x, u16 y) {
	Xil_Out16(BASE_ADDR_TILE_IDX + 2*2*tile_idx, x);
    Xil_Out16(BASE_ADDR_TILE_IDX + 2*2*tile_idx + 2, y);
}

void write_weight(u32 tile_idx, u32 x, u32 y, s8 val) {
	Xil_Out8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS*tile_idx + x * CROSSBAR_NEURONS + y, (u8)val);
}

void write_network_input(u32 x, s8 val) {
	Xil_Out8(BASE_ADDR_INPUT + x, (u8)val);
}

u16 read_spk_out(u32 x) {
	return Xil_In16(BASE_ADDR_SPK + 2*x);
}

u16 read_tile_idx_x(u32 tile_idx) {
    return Xil_In16(BASE_ADDR_TILE_IDX + 4*tile_idx);
}

u16 read_tile_idx_y(u32 tile_idx) {
    return Xil_In16(BASE_ADDR_TILE_IDX + 4*tile_idx + 2);
}

s8 read_weight(u32 tile_idx, u32 x, u32 y) {
    return (s8) Xil_In8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS * tile_idx + x*CROSSBAR_NEURONS + y);
}

s8 read_network_input(u32 x) {
    return (s8) Xil_In8(BASE_ADDR_INPUT + x);
}

void setup_snn() {
	//XGpioPs gpio;	
	//XGpioPs_Config *config;
	//config = XGpioPs_LookupConfig(BASE_ADDR_EN);
	//XGpioPs_CfgInitialize(&gpio, config, config->baseAddr);	
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
	snn_disable();
	while(snn_ready() == 0);
	snn_enable();
	while(snn_done() == 0);
}

void reset_model() {
    for(int i = 0; i < MAX_TILES; i++) {
        for(int j = 0; j < CROSSBAR_NEURONS; j++) {
            for(int k = 0; k < CROSSBAR_NEURONS; k++){
                write_weight(i, j, k, 0);
            }
        }
        write_tile(i, 0, 0);
    }
    for(int i = 0; i < MAX_NEURONS; i++) {
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
