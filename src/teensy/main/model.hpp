#include "uart_driver.hpp"
#include "model_params.hpp"

void write_model(){
    reset_model();

    /*int cur_tile = 0;
    for(int i = 0; i <= 51; i++) {
        write_tile(cur_tile, i, i);
        cur_tile++;
    }*/
    //cur_tile = 0;
    int cur_tile = 0;
    for(int i = 0; i < 0; i++) {
        write_tile(cur_tile, 100, 100);
        cur_tile++;
    }
    

    int tiles = sizeof(tile_idx_x) / sizeof((uint16_t) 0);
    int weight_idx = 0;
    for(int i = 0; i < tiles; i++) {
        Serial.print(cur_tile);
        Serial.print("\n");
        write_tile(cur_tile, tile_idx_x[i], tile_idx_y[i]);
        for(int j = 0; j < 16*16; j++) {
            int idx = weight_idx + j;
            if(weight[idx]) {
                write_weight(i, j / 16, j % 16, weight[idx]); 
                /*Serial.print("write ");
                Serial.print(weight[idx]);
                Serial.print(" got ");
                Serial.print(read_weight(i, j/16, j%16));
                Serial.print("\n");*/
            }
        }
        weight_idx += 16*16;
        cur_tile++;
    }

    int n_input = sizeof(network_input) / 1;
    for(int i = 0; i < n_input; i++) {
        if(network_input[i]) {
            write_network_input(i, network_input[i]);
        }
        if(i%16 == 0) {
            write_tile(cur_tile, i/16, i/16);
            cur_tile++;
        }
    }
}