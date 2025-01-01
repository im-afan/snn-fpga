#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"

int main()
{
    init_platform();
    setup_snn();

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

    cleanup_platform();
    return 0;
}
