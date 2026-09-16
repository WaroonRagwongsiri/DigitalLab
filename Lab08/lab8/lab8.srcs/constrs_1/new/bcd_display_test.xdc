# bcd_display_test.xdc
# Pins for the bin2bcd12 + display isolation test. clk/digit/Seven_Segment
# match lab8_3.xdc exactly; no ADC/SPI pins needed since bin_in is a
# hardcoded constant in this test.

set_property -dict { PACKAGE_PIN H11    IOSTANDARD LVCMOS33 } [get_ports { clk }];

#7 segment display
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports {digit[0]}]; #LSB (Leftmost)
set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33 } [get_ports {digit[1]}];
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports {digit[2]}];
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports {digit[3]}]; #MSB (Rightmost)

set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[7]}];#A
set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[6]}];#B
set_property -dict { PACKAGE_PIN P2    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[5]}];#C
set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[4]}];#D
set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[3]}];#E
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[2]}];#F
set_property -dict { PACKAGE_PIN K4    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[1]}];#G
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[0]}];#DP
