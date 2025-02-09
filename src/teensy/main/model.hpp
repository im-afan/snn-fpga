#include "uart_driver.hpp"
#include "model_params.hpp"

void write_model(){
    //reset_model();

    int tiles = sizeof(tile_idx_x) / sizeof((uint16_t) 0);
    int weight_idx = 0;
    /*for(int i = 0; i < tiles; i++) {
        Serial.print(cur_tile);
        Serial.print("\n");
        write_tile(cur_tile, tile_idx_x[i], tile_idx_y[i]);
        for(int j = 0; j < 16*16; j++) {
            int idx = weight_idx + j;
            if(weight[idx]) {
                write_weight(cur_tile, j / 16, j % 16, weight[idx]); 
            }
        }
        weight_idx += 16*16;
        cur_tile++;
    }*/

    int n_input = sizeof(network_input) / 1;
    for(int i = 0; i < n_input; i++) {
        Serial.print(network_input[i]);
        if(i % 28 == 0) Serial.print("\n");
        write_network_input(i, network_input[i]);
    }
}