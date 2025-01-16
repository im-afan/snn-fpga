#include "uart_driver.hpp"
#include "model_params.hpp"

void write_model(){
    reset_model();

    int tiles = sizeof(tile_idx_x) / sizeof((uint16_t) 0);
    int weight_idx = 0;
    for(int i = 0; i < tiles; i++) {
        Serial.print(i);
        Serial.print("\n");
        write_tile(i, tile_idx_x[i], tile_idx_y[i]);
        for(int j = 0; j < 16*16; j++) {
            int idx = weight_idx + j;
            write_weight(i, j / 16, j % 16, weight[idx]); 
        }
        weight_idx += 16*16;
    }

    int n_input = sizeof(network_input) / 1;
    for(int i = 0; i < n_input; i++) {
        Serial.print(network_input[i]);
        write_network_input(i, network_input[i]);
        if(i%16 == 0) {
          write_tile(tiles + i/16, i/16, i/16);
        }
    }
}