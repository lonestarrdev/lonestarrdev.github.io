`timescale 1ns/1ps

module sram_imag_bank1_wrapper (input clk_a, input en_a, input we_a, input [9:0] addr_a,
 input [23:0] din_a, output [23:0] dout_a, input clk_b, input en_b, input we_b, input [9:0] addr_b, input [23:0] din_b, output [23:0] dout_b);
	wire clk_a_sram;
	wire clk_b_sram;

	assign #1 clk_a_sram = clk_a;
	assign #1 clk_b_sram = clk_b;
	wire cena;
	wire wena;
	wire cenb;
	wire wenb;

	assign cena = ~en_a;
	assign wena = ~we_a;
	assign cenb = ~en_b;
	assign wenb = ~we_b;

	data_imag_bank1 u_sram (
	.QA (dout_a),.QB (dout_b),.CLKA (clk_a_sram),.CENA (cena),.WENA (wena),.AA (addr_a),.DA (din_a),.CLKB (clk_b_sram),
	.CENB (cenb),.WENB (wenb),.AB (addr_b),.DB (din_b),.EMAA (3'b000),.EMAB (3'b000),.RETN (1'b1)
	);/*


behav_dp_1024x24 #(.DW(24)) u_sram (
    .clk_a(clk_a),
    .en_a(en_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),

    .clk_b(clk_b),
    .en_b(en_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b)
); */
endmodule
