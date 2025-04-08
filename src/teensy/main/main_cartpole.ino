#include "uart_host_driver.hpp"
#include "uart_driver.hpp"
#include "cartpole_weights.hpp"
#include "model.hpp"

int cnt = 0;

void setup() {
    Serial.begin(115200);
    //Serial.print("alsdkjfnasdlkjfn\n");
    setup_uart();
    setup_uart_host();
    write_model();
}

void loop() {
    listen();
}
