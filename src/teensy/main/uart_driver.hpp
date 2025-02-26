#pragma once

uint8_t rx_buff[4];

void setup_uart() {
    Serial1.begin(115200);
}

void transfer(uint8_t x) {
    while(!Serial1.availableForWrite());
    Serial1.write(x);
    Serial1.flush();
}

void wait_done() {
    int idx = 0;
    while(Serial1.available() < 4);
    Serial1.readBytes(rx_buff, 4);
}

void write_tile(uint16_t tile_idx, uint16_t x, uint16_t y) {
    transfer(0);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(y >> 8);
    transfer(y % (1 << 8));
    transfer(0);
    wait_done();
}

void write_weight(uint16_t tile_idx, uint8_t x, uint8_t y, int8_t val) {
    transfer(1);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x);
    transfer(y);
    transfer(val);
    transfer(0);
    transfer(0);
    wait_done();
}

int8_t read_weight(uint16_t tile_idx, uint8_t x, uint8_t y) {
    transfer(5);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x);
    transfer(y);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    return rx_buff[0];
}

void write_network_input(uint16_t idx, int8_t val) {
    transfer(2);
    transfer(idx >> 8);
    transfer(idx % (1 << 8));
    transfer(val);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
}

void timestep() {
    transfer(8);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
}

void reset_model() {
    transfer(9);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
}

uint16_t read_spk_out(uint16_t x, uint8_t t) {
    transfer(7);
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(t);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    return (rx_buff[0]) + (rx_buff[1] << 8);
}

int8_t read_network_input(uint16_t x) {
    transfer(6);
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    return rx_buff[0];
}