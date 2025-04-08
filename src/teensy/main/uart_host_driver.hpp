#pragma once
#include "uart_driver.hpp"

/*
 * OPCODE TABLE
 * 0: write_network_input 
 * 1: read_out 
 * 2: timestep
*/

uint8_t rx_buff[4];
uint8_t tx_buff[4];

void setup_uart_host() {
    Serial.begin(115200);
}

void transfer() {
    for(int i = 0; i < 4; i++) {
        while(!Serial.availableForWrite());
        Serial.write(tx_buff[i]);
    }
    Serial.flush();
}

void listen() {
    uint8_t idx = 0;

    while(idx < 4) {
        idx += Serial.readBytes(rx_buff[idx], 1);
    }

    if(op[0] == 0) {
        write_network_input((op[1] << 8) | op[2], op[3]);
        tx_buff[0] = 0;
        transfer();
    } else if(op[0] == 1) {
        uint16_t spk_out = read_spk_out((op[1] << 8) | op[2], op[3]);
        tx_buff[1] = spk_out >> 8;
        tx_buff[0] = spk_out % (1 << 8);
        transfer(); 
    } else if(op[0] == 2) {
        timestep();
        tx_buff[0] = 0;
        transfer();
    }
}