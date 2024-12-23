#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"

// overrides default SNN block memory
// with own weights and runs the neural network
// at a lower frequency and prints the results through UART

int main()
{
    while(1){
       	u16 spk_out = read_spk_out(0);
       	for(int i = 0; i < 16; i++) {
       		xil_printf("%d ", spk_out & (1 << i));
       	}
       	xil_printf("\n\r");
    }

   	cleanup_platform();
    return 0;
}
