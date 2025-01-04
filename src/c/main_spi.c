#include "spi_driver.h"
#include "snn_driver.h"

int main() {
    setup_spi();
    setup_snn();
    while(1) {
        spi_listen();
    }
}