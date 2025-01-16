#include "uart_driver.hpp"
#include "model.hpp"

int cnt = 0;

void setup() {
    Serial.begin(115200);
    setup_uart();
    write_model();
}

void loop() {
    if(cnt == 25) return;

    timestep();

    int x = 0;
    for(int i = 0; i < 784 / 16; i++) {
        uint16_t spk_out = read_spk_out(i);
        for(int j = 0; j < 16; j++) {
            Serial.print((spk_out & (1 << j)) > 0);
            Serial.print(" ");
            x++;
            if(x % 28 == 0) 
                Serial.print("\n");
        }
    }
    Serial.println(read_spk_out(51));
    Serial.print("\n");
    
    delay(100);
    cnt++;
}
