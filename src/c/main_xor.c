#include <stdio.h>
//#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"

int main()
{
    setup_snn();

    write_network_input(0, 127);
    usleep(1000);
    xil_printf("%d\n", read_network_input(0));
    write_tile(0, 3, 3);
    xil_printf("%d\n", read_tile_idx_x(0));

    write_weight(0, 0, 0, 5);
    xil_printf("%d\n", read_weight(0, 0, 0));
    while(1) {
        timestep();
        for(int i = 0; i < 4; i++) {
            u16 spk = read_spk_out(i);
            //u16 spk = Xil_In16(BASE_ADDR_SPK + i);
            for(int j = 0; j < 16; j++) {
                xil_printf("%d ", (spk & (1 << j)) > 0);
            }                        
            
            //xil_printf("%d ", spk);
        }
        xil_printf("\n\r");
        //xil_printf("\n\r");
        usleep(1000000);
    }

    return 0;
}
