#include "spi_driver.h"
#include "snn_driver.h"

int main() {
    setup_spi();
    setup_snn();   
    xil_printf("STARTING SPI TEST\n\r");
    while(1) {
        spi_listen();
        //dump_model(0);
        //xil_printf("input[0] = %d\n\r", read_network_input(0));
        //xil_printf("%d\n\r", read_spk_out(0));
    }
}