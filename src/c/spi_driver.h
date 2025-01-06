#include "xspi.h"
#include "snn_driver.h"
#include "xparameters.h"

#define SPI_BASE_ADDR XPAR_AXI_QUAD_SPI_0_BASEADDR
const u8 SPI_DUMMY = 0xff;

XSpi SpiInstance;
u8 op[8];
/*
 * OPCODE TABLE
 * 0: write_tile_idx
 * 1: write_weight
 * 2: write_input
 * 3: read_tile_idx_x
 * 4: read_tile_idx_y
 * 5: read_weight
 * 6: read_input
 * 7: read_spk_out
 * 8: do timestep
 * 9: reset parameters
*/


void setup_spi() {
    int status;

    XSpi_Config *cfg_pointer = XSpi_LookupConfig(SPI_BASE_ADDR);
    if(cfg_pointer == NULL) xil_printf("lookupconfig failed\n\r");
    status = XSpi_CfgInitialize(&SpiInstance, cfg_pointer, cfg_pointer->BaseAddress);
    if(status != XST_SUCCESS) xil_printf("cfginitialize failed\n\r");
    status = XSpi_SetOptions(&SpiInstance, XSP_CLK_PHASE_1_OPTION | XSP_CLK_ACTIVE_LOW_OPTION);    
    if(status != XST_SUCCESS) xil_printf("setoptions failed\n\r");
    
    XSpi_Start(&SpiInstance);
    XSpi_IntrGlobalDisable(&SpiInstance);
}

void spi_write(u16 x) {
    u8 idx;
    idx = 0;
    u32 y = x; // {done, x}
    while(idx < 4) {
        while(!(XSpi_GetStatusReg(&SpiInstance) & XSP_SR_TX_FULL_MASK) && idx < 4) {
            u8 val = (y % (1 << (idx*8+8))) >> (idx*8);
            //xil_printf("write %d\n", val);
            XSpi_WriteReg(SPI_BASE_ADDR, XSP_DTR_OFFSET, val); 
            idx++;
        }
    }
}

void spi_listen() {
    u8 idx;
    idx = 0;

    while(idx < 8) {
        while(!(XSpi_GetStatusReg(&SpiInstance) & XSP_SR_RX_EMPTY_MASK) && idx < 8) {
            u8 arg = XSpi_ReadReg(SPI_BASE_ADDR, XSP_DRR_OFFSET);
            //xil_printf("%d %d\n\r", idx, arg);
            if(idx == 0 && arg == SPI_DUMMY) continue;
            op[idx] = arg;
            idx++;
        }
    }

    if(op[0] == 0) write_tile((op[1] << 8) | op[2], op[3], op[4]);
    if(op[0] == 1) write_weight((op[1] << 8) | op[2], op[3], op[4], op[5]);
    if(op[0] == 2) write_network_input((op[1] << 8) | op[2], op[3]);
    if(op[0] == 3) spi_write(read_tile_idx_x((op[1] << 8) | op[2]));
    if(op[0] == 4) spi_write(read_tile_idx_y((op[1] << 8) | op[2]));
    if(op[0] == 5) spi_write(read_weight((op[1] << 8) | op[2], op[3], op[4]));
    if(op[0] == 6) spi_write(read_network_input((op[1] << 8) | op[2]));
    if(op[0] == 7) spi_write(read_spk_out((op[1] << 8) | op[2]));
    if(op[0] == 8) timestep();
    if(op[0] == 9) reset_model();
}