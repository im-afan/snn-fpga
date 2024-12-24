#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
//#include "model.h"
//#include "read_model.h"

// overrides default SNN block memory
// with own weights and runs the neural network
// at a lower frequency and prints the results through UART

int main()
{
    init_platform();


    /*for(int i = 0; i < MAX_TILES; i++) {
        u32 idx = Xil_In32(BASE_ADDR_TILE_IDX + 4*i);
        xil_printf("%x\n\r", idx);
    }

    for(int i = 0; i < CROSSBAR_NEURONS; i++) {
        xil_printf("%x ", Xil_In8(BASE_ADDR_WEIGHT + i));
        //Xil_Out8(BASE_ADDR_WEIGHT + CROSSBAR_NEURONS*CROSSBAR_NEURONS + i*CROSSBAR_NEURONS + j, 0);
        
    }
    
    xil_printf("\n\r");
    Xil_Out8(BASE_ADDR_WEIGHT + 5, 32);
    xil_printf("%x\n\r", Xil_In8(BASE_ADDR_WEIGHT + 5));

    for(int i = 0; i < MAX_NEURONS; i++) {
        Xil_Out8(BASE_ADDR_INPUT + i, 0);
    }
    Xil_Out8(BASE_ADDR_INPUT + 0, 32);
    Xil_Out8(BASE_ADDR_INPUT+2, 32);

    u32 snn_in = Xil_In32(BASE_ADDR_INPUT + 0);
    xil_printf("input %x\n\r", snn_in);
    xil_printf("input1 %x\n\r", Xil_In8(BASE_ADDR_INPUT + 47));*/

    for(int i = 0; i < MAX_TILES; i++) {
        xil_printf("%d %d\n\r", read_tile_idx_x(i), read_tile_idx_y(i));
        xil_printf("%x\n\r", Xil_In32(BASE_ADDR_TILE_IDX + 4*i));
    }

    for(int i = 0; i < 1024; i++) {
        xil_printf("%d ", Xil_In32(BASE_ADDR_WEIGHT + i));
    }
    xil_printf("\n\r");

    for(int i = 0; i < MAX_NEURONS; i++) {
        xil_printf("%d ", read_network_input(i));
    }
    xil_printf("\n\r");
    

    while(1) {
        for(int i = 0; i < 1; i++) {
            //u16 spk = read_spk_out(i);
            u16 spk = Xil_In16(BASE_ADDR_SPK + i);
            for(int j = 0; j < 16; j++) {
                xil_printf("%d ", (spk & (1 << j)) > 0);
            }                        
            xil_printf("\n\r");
            //xil_printf("%d ", spk);
        }
        //xil_printf("\n\r");
        usleep(1000000);
    }

    cleanup_platform();
    return 0;
}
