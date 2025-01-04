#include <SPI.h>

#ifndef SPI_DRIVER
#define SPI_DRIVER  

const int SS_PIN = 10; // Slave Select pin
const int DUMMY = 0xff;
volatile bool done = false;

void setup_spi() {
    pinMode(SS_PIN, OUTPUT);
    SPI.begin();
}

void transfer(uint8_t x) {
    SPI.transfer(x);
    delayMicroseconds(100);
}

uint16_t wait_done() {
    delayMicroseconds(10000);
    return SPI.transfer(DUMMY);
}

void write_tile(uint16_t tile_idx, uint16_t x, uint16_t y) {
    digitalWrite(SS_PIN, LOW);
    transfer(0);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(y >> 8);
    transfer(y % (1 << 8));
    transfer(0);
    wait_done();
    digitalWrite(SS_PIN, HIGH);
}

void write_weight(uint16_t tile_idx, uint8_t x, uint8_t y, int8_t val) {
    digitalWrite(SS_PIN, LOW);
    transfer(1);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x);
    transfer(y);
    transfer(val);
    transfer(0);
    transfer(0);
    wait_done();
    digitalWrite(SS_PIN, HIGH);

}

void write_network_input(uint16_t idx, int8_t val) {
    digitalWrite(SS_PIN, LOW);
    transfer(2);
    transfer(idx >> 8);
    transfer(idx % (1 << 8));
    transfer(val);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    digitalWrite(SS_PIN, HIGH);

}

void timestep() {
    digitalWrite(SS_PIN, LOW);
    transfer(8);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    digitalWrite(SS_PIN, HIGH);

}

void reset_model() {
    digitalWrite(SS_PIN, LOW);
    transfer(9);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done();
    digitalWrite(SS_PIN, HIGH);

}

uint16_t read_spk_out(uint16_t x) {
    digitalWrite(SS_PIN, LOW);
    transfer(7);
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    uint16_t res = wait_done();
    digitalWrite(SS_PIN, HIGH);
    return res;
}
/*
ISR(SPI_STC_vect) {
    done = true;
}*/

#endif