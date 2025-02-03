#include <stdio.h>
//#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
#include "model_params.h"

int main()
{
    setup_snn();

    for(int i = 0; i < 28*28; i++) {
        network_input[i] = 2;
        write_network_input(i, network_input[i]);
        //write_network_input(i, network_input[i]);
    }

    for(int i = 0; i < 28; i++) {
        for(int j = 0; j < 28; j++) xil_printf("%d ", read_network_input(i*28+j) != network_input[i*28+j]);
            //xil_printf("%d ", network_input[i*28+j]);
        xil_printf("\n\r");
    }

    int print_img = 0;
    int cnt = 0;

    while(1) {
        timestep();

        if(print_img) {
            int x = 0;
            for(int i = 0; i < 28*28/16; i++) {
                u16 spk = read_spk_out(i);
                //u16 spk = Xil_In16(BASE_ADDR_SPK + i);
                for(int j = 0; j < 16; j++) {
                    xil_printf("%d ", (spk & (1 << j)) > 0);
                    x++;
                    if(x % 28 == 0) xil_printf("\n\r");
                }                        
                //xil_printf("%d ", spk);
            }
        }

        xil_printf("spk_out: ");
        u16 spk = read_spk_out(59);
        for(int i = 0; i < 10; i++) {
            xil_printf("%d", (spk & (1 << i)) > 0);
        }

        xil_printf("\n\r");
        //xil_printf("\n\r");
        //usleep(1000000);
        if(cnt++ > 100) break;
    }

    return 0;
}
