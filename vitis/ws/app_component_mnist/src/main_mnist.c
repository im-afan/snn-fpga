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
        write_network_input(i, network_input[i]);
    }


    int print_img = 0;
    int cnt = 0;

    timestep();

    for(int i = 0; i < 128; i++) {
        xil_printf("spk_out: ");
        u16 spk = read_spk_out(1, i);
        for(int i = 0; i < 10; i++) {
            xil_printf("%d", (spk & (1 << i)) > 0);
        }
        xil_printf("\n\r");
    }

    return 0;
}
