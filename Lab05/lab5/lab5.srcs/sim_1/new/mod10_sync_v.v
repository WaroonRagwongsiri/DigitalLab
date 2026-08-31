`timescale 1ns/1ps
// Verilog port of mod10_sync, mirroring the current VHDL:
//  - n17_o decodes state 9 (1001) AND the incoming enable (last_output),
//    same RCO = TC & CE technique as mod5_sync_v -- keeps the pulse one
//    raw clock wide regardless of how wide last_output itself is.
//  - the async clear is driven by n19_q, a registered (one-cycle-delayed)
//    copy of n17_o, avoiding a combinational feedback loop.
module mod10_sync_v (
    input  wire last_output,
    input  wire clk,
    output wire mod10_out
);
    reg n1_q, n1_qn, n2_q, n2_qn, n5_q, n5_qn, n10_q, n10_qn;
    reg n19_q, n19_qn;
    wire n3_o, n6_o, n11_o, n17_o;

    assign n3_o  = last_output & n1_q;
    assign n6_o  = n3_o & n2_q;
    assign n11_o = n6_o & n5_q;
    assign n17_o = n10_q & n5_qn & n2_qn & n1_q & last_output;  // state 9 AND enabled

    initial begin
        n1_q = 1'b0; n1_qn = 1'b1;
        n2_q = 1'b0; n2_qn = 1'b1;
        n5_q = 1'b0; n5_qn = 1'b1;
        n10_q = 1'b0; n10_qn = 1'b1;
        n19_q = 1'b0; n19_qn = 1'b1;
    end

    always @(posedge clk or posedge n19_q) begin
        if (n19_q) begin
            n1_q <= 1'b0; n1_qn <= 1'b1;
        end else if (last_output) begin
            n1_q <= ~n1_q; n1_qn <= ~n1_qn;
        end
    end

    always @(posedge clk or posedge n19_q) begin
        if (n19_q) begin
            n2_q <= 1'b0; n2_qn <= 1'b1;
        end else if (n3_o) begin
            n2_q <= ~n2_q; n2_qn <= ~n2_qn;
        end
    end

    always @(posedge clk or posedge n19_q) begin
        if (n19_q) begin
            n5_q <= 1'b0; n5_qn <= 1'b1;
        end else if (n6_o) begin
            n5_q <= ~n5_q; n5_qn <= ~n5_qn;
        end
    end

    always @(posedge clk or posedge n19_q) begin
        if (n19_q) begin
            n10_q <= 1'b0; n10_qn <= 1'b1;
        end else if (n11_o) begin
            n10_q <= ~n10_q; n10_qn <= ~n10_qn;
        end
    end

    always @(posedge clk) begin
        n19_q  <= n17_o;
        n19_qn <= ~n17_o;
    end

    assign mod10_out = n17_o;
endmodule
