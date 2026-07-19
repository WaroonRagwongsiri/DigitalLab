//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sun Jul 19 22:19:08 2026
//Host        : LAPTOP-2P21F8GO running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=13,numReposBlks=13,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (D14,
    SW17,
    SW19,
    SW21,
    SW22);
  (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 DATA.D14 DATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DATA.D14, LAYERED_METADATA undef" *) output [0:0]D14;
  input SW17;
  input SW19;
  input SW21;
  (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 DATA.SW22 DATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DATA.SW22, LAYERED_METADATA undef" *) input SW22;

  wire [0:0]D14;
  wire SW17;
  wire SW19;
  wire SW21;
  wire SW22;
  wire [0:0]ilvector_logic_0_Res;
  wire [0:0]ilvector_logic_10_Res;
  wire [0:0]ilvector_logic_11_Res;
  wire [0:0]ilvector_logic_1_Res;
  wire [0:0]ilvector_logic_2_Res;
  wire [0:0]ilvector_logic_3_Res;
  wire [0:0]ilvector_logic_4_Res;
  wire [0:0]ilvector_logic_5_Res;
  wire [0:0]ilvector_logic_6_Res;
  wire [0:0]ilvector_logic_7_Res;
  wire [0:0]ilvector_logic_8_Res;
  wire [0:0]ilvector_logic_9_Res;

  assign ilvector_logic_0_Res = ~ SW22;
  assign ilvector_logic_1_Res = ilvector_logic_3_Res & ilvector_logic_4_Res;
  assign ilvector_logic_10_Res = ilvector_logic_1_Res | ilvector_logic_5_Res;
  assign ilvector_logic_11_Res = ilvector_logic_10_Res | ilvector_logic_7_Res;
  assign D14 = ilvector_logic_11_Res | ilvector_logic_9_Res;
  assign ilvector_logic_2_Res = ~ SW21;
  assign ilvector_logic_3_Res = ~ SW19;
  assign ilvector_logic_4_Res = ~ SW17;
  assign ilvector_logic_5_Res = ilvector_logic_0_Res & ilvector_logic_2_Res;
  assign ilvector_logic_6_Res = SW22 & SW21;
  assign ilvector_logic_7_Res = ilvector_logic_6_Res & SW17;
  assign ilvector_logic_8_Res = ilvector_logic_2_Res & SW19;
  assign ilvector_logic_9_Res = ilvector_logic_8_Res & ilvector_logic_4_Res;
endmodule
