#include "xbram.h"

XBram_Config XBram_ConfigTable[] __attribute__ ((section (".drvcfg_sec"))) = {

	{
		"xlnx,axi-bram-ctrl-4.1", /* compatible */
		0xc0000000, /* reg */
		0x0, /* xlnx,bram-data-width */
		0x0, /* xlnx,bram-ecc-present */
		0x0, /* xlnx,bram-fault-injection-present */
		0x0, /* xlnx,bram-correctable-failing-registers */
		0x0, /* xlnx,bram-correctable-failing-data-regs */
		0x0, /* xlnx,bram-uncorrectable-failing-registers */
		0x0, /* xlnx,bram-uncorrectable-failing-data-regs */
		0x0, /* xlnx,bram-ecc-status-interrupt-present */
		0x0, /* xlnx,bram-correctable-counter-bits */
		0x0, /* xlnx,bram-ecc-on-off-register */
		0x0, /* xlnx,bram-ecc-on-off-reset-value */
		0x0, /* xlnx,bram-write-access */
		0x0, /* xlnx,bram-mem-base-address */
		0x0, /* xlnx,bram-mem-high-address */
		0x0, /* xlnx,bram-mem-ctrl-base-address */
		0x0, /* xlnx,bram-mem-ctrl-high-address */
		0xffff, /* interrupts */
		0xffff /* interrupt-parent */
	},
	 {
		 NULL
	}
};