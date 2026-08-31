`timescale 1ns/1ps
// Verilog port of mod5_sync, mirroring the current VHDL:
//  - n12_o decodes state 4 (100) AND the incoming enable (last_output),
//    same as a real cascaded counter's RCO = TC & CE. This keeps the
//    pulse exactly one raw clock wide even when last_output is itself
//    a multi-clock-wide pulse from an upstream stage (every stage past
//    the first), instead of over-toggling the next stage.
//  - the async clear is driven by n13_q, a REGISTERED (one-cycle-delayed)
//    copy of n12_o, instead of a combinational decode feeding back into
//    the same flip-flops -- avoids a combinational feedback loop.
module mod5_sync_v (
    input  wire last_output,
    input  wire clk,
    output wire mod5_out
);
    reg n1_q, n1_qn, n2_q, n2_qn, n5_q, n5_qn;
    reg n13_q, n13_qn;
    wire n3_o, n6_o, n12_o;

    assign n3_o  = last_output & n1_q;
    assign n6_o  = n3_o & n2_q;
    assign n12_o = n5_q & n2_qn & n1_qn & last_output;   // state 4 AND enabled

    initial begin
        n1_q = 1'b0; n1_qn = 1'b1;
        n2_q = 1'b0; n2_qn = 1'b1;
        n5_q = 1'b0; n5_qn = 1'b1;
        n13_q = 1'b0; n13_qn = 1'b1;
    end

    always @(posedge clk or posedge n13_q) begin
        if (n13_q) begin
            n1_q <= 1'b0; n1_qn <= 1'b1;
        end else if (last_output) begin
            n1_q <= ~n1_q; n1_qn <= ~n1_qn;
        end
    end

    always @(posedge clk or posedge n13_q) begin
        if (n13_q) begin
            n2_q <= 1'b0; n2_qn <= 1'b1;
        end else if (n3_o) begin
            n2_q <= ~n2_q; n2_qn <= ~n2_qn;
        end
    end

    always @(posedge clk or posedge n13_q) begin
        if (n13_q) begin
            n5_q <= 1'b0; n5_qn <= 1'b1;
        end else if (n6_o) begin
            n5_q <= ~n5_q; n5_qn <= ~n5_qn;
        end
    end

    always @(posedge clk) begin
        n13_q  <= n12_o;
        n13_qn <= ~n12_o;
    end

    assign mod5_out = n12_o;
endmodule
