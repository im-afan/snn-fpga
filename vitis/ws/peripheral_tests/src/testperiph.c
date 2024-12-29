
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"

#include "xgpio.h"
#include "gpio_header.h"

#include "xuartlite.h"
#include "uartlite_header.h"
int main ()
{

    static XGpio axi_gpio_0;

    print("---Entering main---\n\r");

    {
        int status;
        print("\r\nRunning GpioOutputExample for axi_gpio_0 ... \r\n");
        status = GpioOutputExample(&axi_gpio_0, XPAR_AXI_GPIO_0_BASEADDR);
        if (status == 0) {
            print("GpioOutputExample PASSED \r\n");
        } else {
            print("GpioOutputExample FAILED \r\n");
        }
    }

    print("---Exiting main---");
    return 0;
}
