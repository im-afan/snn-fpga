#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
//#include "xgpio.h"
//#include "xbram.h"
#include "xparameters.h"
#include "xil_io.h"
/*
const uint32_t BASE_ADDR = XPAR_AXI_BRAM_CTRL_0_BASEADDR;
const uint32_t MAX_NEURONS = 64;
const uint32_t WEIGHT_OFFSET = 0;
const uint32_t NETWORK_INPUT_OFFSET = MAX_NEURONS*MAX_NEURONS;
const uint32_t SPK_OUT_OFFSET = MAX_NEURONS*MAX_NEURONS + MAX_NEURONS;
const uint32_t ENABLE_OFFSET = MAX_NEURONS*MAX_NEURONS + 2*MAX_NEURONS;
*/
#ifndef SNN_DRIVER
#define SNN_DRIVER

const uint32_t BASE_ADDR = XPAR_AXI_BRAM_CTRL_0_BASEADDR;

const uint32_t MAX_TILES = 32;
const uint32_t NEURONS_PER_TILE = 16;
const uint32_t BYTES_PER_WIDTH = 128 / 8;
const uint32_t MAX_NEURONS = 1024;

const uint32_t TILE_WIDTH = BYTES_PER_WIDTH + NEURONS_PER_TILE*NEURONS_PER_TILE;
const uint32_t WEIGHT_OFFSET = 0; // word 1: core index, word 2...NEURONS_PER_TILE: weights
const uint32_t NETWORK_INPUT_OFFSET = TILE_WIDTH * MAX_TILES;
const uint32_t SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + MAX_NEURONS;
const uint32_t ENABLE_OFFSET = SPK_OUT_OFFSET + MAX_NEURONS;
const uint32_t FLAGS_OFFSET = SPK_OUT_OFFSET + MAX_NEURONS;
const uint32_t MEM_OFFSET = FLAGS_OFFSET + MAX_NEURONS;

void write_tile(uint32_t tile_idx, u8 x, u8 y) {
    xil_printf("write_tile idx %d = %d %d\n\r", tile_idx, x, y);
	Xil_Out8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx, y);
    Xil_Out8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx + 1, x);
    xil_printf("got x = %d\n\r", Xil_In8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx + 1));
}

void write_weight(uint32_t tile_idx, uint32_t x, uint32_t y, uint32_t val) {
	Xil_Out8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx + BYTES_PER_WIDTH + x * NEURONS_PER_TILE + y, val);
}


void write_network_input(uint32_t x, uint32_t val) {
	Xil_Out8(BASE_ADDR + NETWORK_INPUT_OFFSET + x, val);
}

void write_enable(uint32_t val) {
	Xil_Out8(BASE_ADDR + 1*ENABLE_OFFSET, val);
}

void write_mem(u32 x, s8 val) {
	Xil_Out8(BASE_ADDR + MEM_OFFSET + x, val);
}

/*void write_reset(uint32_t val) {
	Xil_Out8(BASE_ADDR + 1*SNN_RST_OFFSET, val);
}*/

u8 read_tile_x(uint32_t tile_idx){
	return (u8)Xil_In8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx + 1);
	//return Xil_In8(BASE_ADDR + 1*(WEIGHT_OFFSET + x*MAX_NEURONS + y));
}

u8 read_tile_y(uint32_t tile_idx) {
    return (u8)Xil_In8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx);
}

s8 read_weight(uint32_t tile_idx, uint32_t x, uint32_t y){
	return (s8)Xil_In8(BASE_ADDR + WEIGHT_OFFSET + TILE_WIDTH*tile_idx + BYTES_PER_WIDTH + x * NEURONS_PER_TILE + y);
	//return Xil_In8(BASE_ADDR + 1*(WEIGHT_OFFSET + x*MAX_NEURONS + y));
}

s8 read_network_input(uint32_t x) {
	return (s8)Xil_In8(BASE_ADDR + 1*(NETWORK_INPUT_OFFSET + x));
}

uint32_t read_spk_out(uint32_t x) {
	return Xil_In8(BASE_ADDR + 1*(SPK_OUT_OFFSET + x));
}

uint32_t read_enable() {
	return Xil_In8(BASE_ADDR + ENABLE_OFFSET);
}

s8 read_mem(uint32_t x) {
    return (s8)Xil_In8(BASE_ADDR + MEM_OFFSET + x);
}

//void timestep(int timeout, int* output = NULL) {
void timestep(int timeout) {
	write_enable(0);
	usleep(timeout); // maybe include a done signal instead
	write_enable(1);
	usleep(timeout); // maybe include a done signal instead
	/*if(output != NULL) {
		for(int i = 0; i < MAX_NEURONS; i++) {
			output[i] = read_spk_out(i);
		}
	}*/
}

void reset_network() {
	for(int i = 0; i < MAX_NEURONS; i++) {
		write_network_input(i, 0);
		write_mem(i, 0);
	}
}
#endif
