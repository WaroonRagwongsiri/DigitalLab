`timescale 1ns/1ps
// Verilog port of mod50m_sync: one mod5_sync_v stage + seven mod10_sync_v
// stages chained together, dividing the 50 MHz input clock down to 1 Hz
// (50,000,000 = 5 * 10^7).
module mod50m_sync_v (
    input  wire clk,
    output wire clk_mod50m
);
    wire w1, w2, w3, w4, w5, w6, w7, w8;

    mod5_sync_v  u0 (.last_output(1'b1), .clk(clk), .mod5_out(w1));
    mod10_sync_v u1 (.last_output(w1),   .clk(clk), .mod10_out(w2));
    mod10_sync_v u2 (.last_output(w2),   .clk(clk), .mod10_out(w3));
    mod10_sync_v u3 (.last_output(w3),   .clk(clk), .mod10_out(w4));
    mod10_sync_v u4 (.last_output(w4),   .clk(clk), .mod10_out(w5));
    mod10_sync_v u5 (.last_output(w5),   .clk(clk), .mod10_out(w6));
    mod10_sync_v u6 (.last_output(w6),   .clk(clk), .mod10_out(w7));
    mod10_sync_v u7 (.last_output(w7),   .clk(clk), .mod10_out(w8));

    assign clk_mod50m = w8;
endmodule
