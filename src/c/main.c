#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
#include "model.h"
//#include "read_model.h"

// overrides default SNN block memory
// with own weights and runs the neural network
// at a lower frequency and prints the results through UART

int main()
{
    init_platform();
    setup_snn();
    reset_model();
    write_model();

    write_tile(6, 0, 0);
    write_tile(7, 1, 1);
    write_tile(8, 2, 2);
    write_tile(9, 3, 3);
    //reset_model();
    dump_model(0);
    //read_model();

    print("\n\r--------BEGINNING SNN INFERENCE--------------\n\r");

    int cnt = 0;
    int timesteps = 0;

    int vote[10];
    for(int i = 0; i < 10; i++) {
        vote[i] = 0;
    }

    while(1){
        timestep();
        
        u16 spk = read_spk_out(6);
        
        for(int i = 0; i < 16; i++) {
            int spki = (spk & (1 << i)) > 0;
            xil_printf("%d ", spki);
            if(i < 10) vote[i] += spki;
        }

        xil_printf("\n\r");

        cnt++;
        if(cnt == 100) break;
    }

    xil_printf("\n\rspike voting: ");
    int mx = 0;
    int mx_ind = -1;
    for(int i = 0; i < 10; i++){
        if(vote[i] > mx) {
            mx_ind = i;
            mx = vote[i];
        }
        xil_printf("%d ", vote[i]);
    }

    xil_printf("\n\rI think this is %d!\n\r", mx_ind);

    cleanup_platform();
    return 0;
}