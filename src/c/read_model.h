/*
 * reads model from host computer via UART
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "snn_driver.h"
#include "model.h"

#ifndef READ_MODEL
#define READ_MODEL

void read_model(){
	int cnt = 0;
	while(1){
		char s[10];
		gets(s);
		
		char* tok = strtok(s, " ");
		int arg[4];
		int idx = 0;
		while(tok != NULL) {
			arg[idx] = atoi(tok);
			tok = strtok(NULL, " ");
		}

		if(arg[0] == 0){ // write tile idx 
			write_tile(arg[1], arg[2], arg[3]);
		} else if(arg[0] == 1){ // write weight 
			write_weight(arg[1], arg[2], arg[3], arg[4]);
		} else if(arg[0] == 2){ // write network input
			write_network_input(arg[1], arg[2]);	
		}

	}
}

#endif
