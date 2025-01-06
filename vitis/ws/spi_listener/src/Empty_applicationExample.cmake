set(DDR lmb_bram_0)
set(lmb_bram_0 "0x50;0x3fb0")
set(axi_bram_0 "0xc0000000;0x2000")
set(axi_bram_1 "0xc2000000;0x2000")
set(axi_bram_2 "0xc4000000;0x2000")
set(axi_bram_3 "0xc6000000;0x2000")
set(TOTAL_MEM_CONTROLLERS "lmb_bram_0;axi_bram_0;axi_bram_1;axi_bram_2;axi_bram_3")
set(MEMORY_SECTION "MEMORY
{
	lmb_bram_0 : ORIGIN = 0x50, LENGTH = 0x3fb0
	axi_bram_0 : ORIGIN = 0xc0000000, LENGTH = 0x2000
	axi_bram_1 : ORIGIN = 0xc2000000, LENGTH = 0x2000
	axi_bram_2 : ORIGIN = 0xc4000000, LENGTH = 0x2000
	axi_bram_3 : ORIGIN = 0xc6000000, LENGTH = 0x2000
}")
set(STACK_SIZE 0x400)
set(HEAP_SIZE 0x800)
