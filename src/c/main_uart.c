#include "uart_driver.h"
#include "snn_driver.h"

int main() {
    setup_uart();
    setup_snn();
    while(1) {
        listen();
    }
}