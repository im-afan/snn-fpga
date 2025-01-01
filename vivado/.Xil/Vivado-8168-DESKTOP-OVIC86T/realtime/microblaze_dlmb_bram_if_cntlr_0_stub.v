// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "microblaze_dlmb_bram_if_cntlr_0,lmb_bram_if_cntlr,{}" *) (* core_generation_info = "microblaze_dlmb_bram_if_cntlr_0,lmb_bram_if_cntlr,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=lmb_bram_if_cntlr,x_ipVersion=4.0,x_ipCoreRevision=25,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_FAMILY=artix7,C_HIGHADDR=0x0000000000003FFF,C_BASEADDR=0x0000000000000000,C_NUM_LMB=1,C_MASK=0x0000000040000000,C_MASK1=0x0000000000800000,C_MASK2=0x0000000000800000,C_MASK3=0x0000000000800000,C_MASK4=0x0000000000800000,C_MASK5=0x0000000000800000,C_MASK6=0x0000000000800000,C_MASK7=0x0000000000800000,C_LMB_AWIDTH=32,C_LMB_DWIDTH=32,C_LMB_PROTOCOL=0,C_ARBITRATION=0,C_ECC=0,C_INTERCONNECT=0,C_FAULT_INJECT=0,C_CE_FAILING_REGISTERS=0,C_UE_FAILING_REGISTERS=0,C_ECC_STATUS_REGISTERS=0,C_ECC_ONOFF_REGISTER=0,C_ECC_ONOFF_RESET_VALUE=1,C_CE_COUNTER_WIDTH=0,C_WRITE_ACCESS=2,C_BRAM_AWIDTH=32,C_S_AXI_CTRL_ADDR_WIDTH=32,C_S_AXI_CTRL_DATA_WIDTH=32}" *) (* downgradeipidentifiedwarnings = "yes" *) 
(* x_core_info = "lmb_bram_if_cntlr,Vivado 2024.2" *) 
module microblaze_dlmb_bram_if_cntlr_0(LMB_Clk, LMB_Rst, LMB_ABus, LMB_WriteDBus, 
  LMB_AddrStrobe, LMB_ReadStrobe, LMB_WriteStrobe, LMB_BE, Sl_DBus, Sl_Ready, Sl_Wait, Sl_UE, 
  Sl_CE, BRAM_Rst_A, BRAM_Clk_A, BRAM_Addr_A, BRAM_EN_A, BRAM_WEN_A, BRAM_Dout_A, BRAM_Din_A);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 CLK.LMB_Clk CLK" *) (* x_interface_mode = "slave CLK.LMB_Clk" *) (* x_interface_parameter = "XIL_INTERFACENAME CLK.LMB_Clk, ASSOCIATED_BUSIF SLMB:SLMB1:SLMB2:SLMB3:SLMB4:SLMB5:SLMB6:SLMB7, ASSOCIATED_RESET LMB_Rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_0_clk_out1, INSERT_VIP 0" *) input LMB_Clk /* synthesis syn_isclock = 1 */;
  (* x_interface_info = "xilinx.com:signal:reset:1.0 RST.LMB_Rst RST" *) (* x_interface_mode = "slave RST.LMB_Rst" *) (* x_interface_parameter = "XIL_INTERFACENAME RST.LMB_Rst, POLARITY ACTIVE_HIGH, TYPE INTERCONNECT, INSERT_VIP 0" *) input LMB_Rst;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB ABUS" *) (* x_interface_mode = "slave SLMB" *) (* x_interface_parameter = "XIL_INTERFACENAME SLMB, ADDR_WIDTH 32, DATA_WIDTH 32, READ_WRITE_MODE READ_WRITE, PROTOCOL STANDARD" *) input [0:31]LMB_ABus;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB WRITEDBUS" *) input [0:31]LMB_WriteDBus;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB ADDRSTROBE" *) input LMB_AddrStrobe;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB READSTROBE" *) input LMB_ReadStrobe;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB WRITESTROBE" *) input LMB_WriteStrobe;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB BE" *) input [0:3]LMB_BE;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB READDBUS" *) output [0:31]Sl_DBus;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB READY" *) output Sl_Ready;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB WAIT" *) output Sl_Wait;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB UE" *) output Sl_UE;
  (* x_interface_info = "xilinx.com:interface:lmb:1.0 SLMB CE" *) output Sl_CE;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT RST" *) (* x_interface_mode = "master BRAM_PORT" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORT, MEM_SIZE 16384, MASTER_TYPE BRAM_CTRL, MEM_WIDTH 32, MEM_ECC NONE, READ_LATENCY 1" *) output BRAM_Rst_A;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT CLK" *) output BRAM_Clk_A /* synthesis syn_isclock = 1 */;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT ADDR" *) output [0:31]BRAM_Addr_A;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT EN" *) output BRAM_EN_A;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT WE" *) output [0:3]BRAM_WEN_A;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT DIN" *) output [0:31]BRAM_Dout_A;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORT DOUT" *) input [0:31]BRAM_Din_A;
endmodule
