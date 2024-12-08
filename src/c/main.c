#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
#include "model.h"

// overrides default SNN block memory
// with own weights and runs the neural network
// at a lower frequency and prints the results through UART

int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application\n\r");

    /*for(int i = 0; i < MAX_NEURONS; i++) {
        for(int j = 0; j < MAX_NEURONS; j++) {
            write_weight(i, j, 0);
            //write_delay(i, j, 1);
        } 
    }

    write_weight(0, 32, 32);
    write_weight(0, 56, -32);
    write_weight(1, 32, -32);
    write_weight(1, 56, 32);
    write_weight(32, 63, 32);
    write_weight(56, 63, 32);

    reset_network();
    write_network_input(0, 32);*/

    //write_network_input(0, 0);
    

    int cnt = 0;
    int timesteps = 0;
    while(1){
        timestep(100);
        //usleep(500);
        cnt++;
        //if(cnt == 5) write_network_input(1, 32);
        if(cnt % (MAX_NEURONS / NEURONS_PER_CORE) == 0) {
            timesteps++;
            for(int i = 0; i < 20; i++) xil_printf("%d ", read_spk_out(i));
            xil_printf("\n\r");
            usleep(1000000);
        }
    }

    cleanup_platform();
    return 0;
}
