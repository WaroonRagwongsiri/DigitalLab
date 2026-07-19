//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sun Jul 19 22:19:08 2026
//Host        : LAPTOP-2P21F8GO running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (D14,
    SW17,
    SW19,
    SW21,
    SW22);
  output [0:0]D14;
  input SW17;
  input SW19;
  input SW21;
  input SW22;

  wire [0:0]D14;
  wire SW17;
  wire SW19;
  wire SW21;
  wire SW22;

  design_1 design_1_i
       (.D14(D14),
        .SW17(SW17),
        .SW19(SW19),
        .SW21(SW21),
        .SW22(SW22));
endmodule
