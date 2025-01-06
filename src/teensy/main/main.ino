#include <SPI.h>
#include "spi_driver.hpp"
#include "model.hpp"

int cnt = 0;

void setup() {
    Serial.begin(115200);
    setup_spi(); 

    reset_model();
    //write_network_input(0, 63);
    //write_network_input(1, 64);
    //write_network_input(2, 47);
    write_model();
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
