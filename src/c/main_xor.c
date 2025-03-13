#include <stdio.h>
//#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"

int main()
{
    setup_snn();
    reset_model();
    
    write_tile(0, 0, 0, 0, 0);
    write_weight(0, 0, 2, 64);
    write_weight(0, 1, 2, -64);
    write_weight(0, 0, 3, -64);
    write_weight(0, 1, 3, 64);
    write_weight(0, 2, 4, 64);
    write_weight(0, 3, 4, 64);
    write_network_input(0, 64);

    timestep();

    for(int i = 0; i < 128; i++) {
        xil_printf("spk_out: ");
        u16 spk = read_spk_out(0, i);
        for(int i = 0; i < 10; i++) {
            xil_printf("%d", (spk & (1 << i)) > 0);
        }
        xil_printf("\n\r");
    }

    return 0;
}
