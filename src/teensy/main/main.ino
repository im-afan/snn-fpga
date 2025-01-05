#include <SPI.h>
#include "spi_driver.hpp"
#include "model.hpp"

int cnt = 0;

void setup() {
    Serial.begin(9600);
    setup_spi(); 

    reset_model();
    write_model();
    write_tile(6, 0, 0);
    write_tile(7, 1, 1);
    write_tile(8, 2, 2);
    write_tile(9, 3, 3);
}

void loop() {
    cnt++;
    if(cnt < 25){
        timestep();
        Serial.print(read_spk_out(0));
        Serial.print("\n");
    }

    delay(1000);
}
