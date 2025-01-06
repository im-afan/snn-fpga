#include "spi_driver.h"
#include "snn_driver.h"

int main() {
    setup_spi();
    setup_snn();
    while(1) {
        spi_listen();
        xil_printf("%d\n\r", read_spk_out(0));
        for(int i = 0; i < 16; i++) {
            xil_printf("%d ", read_network_input(i));
        }
        xil_printf("\n\r");
    }
}