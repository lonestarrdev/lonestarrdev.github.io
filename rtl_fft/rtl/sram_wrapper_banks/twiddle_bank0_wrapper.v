`timescale 1ns/1ps

module twiddle_bank0_wrapper (input clk, input en, input we,input [8:0]  addr,input [15:0] din, output [15:0] dout
);

    wire cen;
    wire wen;

    assign cen = ~en;
    assign wen = ~we;
    wire clk_sram;
    assign #1 clk_sram = clk;
    twiddle_bank0 u_sram (
        .Q    (dout),
        .CLK  (clk_sram),
        .CEN  (cen),
        .WEN  (wen),
        .A    (addr),
        .D    (din),
        .EMA  (3'b000),
        .RETN (1'b1)
    );/*
behav_sp_512x16 u_sram (
    .clk(clk),
    .en(en),
    .we(we),
    .addr(addr),
    .din(din),
    .dout(dout)
);*/

endmodule
