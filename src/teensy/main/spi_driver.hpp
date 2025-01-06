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

uint32_t wait_done(int time) {
    delayMicroseconds(time);
    SPI.transfer(DUMMY);
    uint32_t res = 0;
    for(int i = 0; i < 4; i++) {
        uint8_t x = SPI.transfer(DUMMY);
        res = res | (x << 8*i);
    }
    return res;
}

void write_tile(uint16_t tile_idx, uint16_t x, uint16_t y) {
    Serial.print("write_tile ");
    Serial.print(tile_idx);
    Serial.print("\n");
    digitalWrite(SS_PIN, LOW);
    transfer(0);
    transfer(tile_idx >> 8);
    transfer(tile_idx % (1 << 8));
    transfer(x >> 8);
    transfer(x % (1 << 8));
    transfer(y >> 8);
    transfer(y % (1 << 8));
    transfer(0);
    wait_done(10000);
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
    wait_done(10000);
    digitalWrite(SS_PIN, HIGH);

}

void write_network_input(uint16_t idx, int8_t val) {
    Serial.print("write input ");
    Serial.print(idx);
    Serial.print(" ");
    Serial.print(val);
    Serial.print("\n");
    digitalWrite(SS_PIN, LOW);
    transfer(2);
    transfer(idx >> 8);
    transfer(idx % (1 << 8));
    transfer(val);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done(10000);
    digitalWrite(SS_PIN, HIGH);

}

void timestep() {
    Serial.print("send timestep req\n");  
    digitalWrite(SS_PIN, LOW);
    transfer(8);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    transfer(0);
    wait_done(50000);
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
    wait_done(50000);
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
    uint32_t res = wait_done(1000);
    digitalWrite(SS_PIN, HIGH);
    return res;
}
/*
ISR(SPI_STC_vect) {
    done = true;
}*/

#endif