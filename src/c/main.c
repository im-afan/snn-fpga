#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
//#include "model.h"
#include "read_model.h"

// overrides default SNN block memory
// with own weights and runs the neural network
// at a lower frequency and prints the results through UART

int main()
{
    init_platform();
    //write_model();
	read_model();

    print("\n\r--------BEGINNING SNN INFERENCE--------------\n\r");

    int cnt = 0;
    int timesteps = 0;

    int vote[10];
    for(int i = 0; i < 10; i++) {
        vote[i] = 0;
    }

    while(1){
        if(timesteps == 100) break;
        timestep(100);
        if(cnt % (MAX_NEURONS / NEURONS_PER_TILE + 1) == 0) {
            timesteps++;
            for(int i = 7*NEURONS_PER_TILE; i < 7*NEURONS_PER_TILE+10; i++) {
                int spk = read_spk_out(i);
                vote[i - 7*NEURONS_PER_TILE] += spk;
                xil_printf("%d ", spk);

            }
            xil_printf("\n\r");
            usleep(10000);
        }
        cnt++;
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
