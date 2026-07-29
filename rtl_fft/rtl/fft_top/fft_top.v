`timescale 1ns/1ps

module fft_top #(parameter DW = 24) ( //oh boy its timne for a billion inputs
    input clk,
    input rst_n,
    input start,
    output done,
    input tb_mode,
    // bank0 real
    input tb_b0r_en_a,
    input tb_b0r_we_a,
    input [9:0] tb_b0r_addr_a,
    input [DW-1:0] tb_b0r_din_a,
    output [DW-1:0] tb_b0r_dout_a,
    input tb_b0r_en_b,
    input tb_b0r_we_b,
    input [9:0] tb_b0r_addr_b,
    input [DW-1:0] tb_b0r_din_b,
    output [DW-1:0] tb_b0r_dout_b,

    // ank0 imag
    input tb_b0i_en_a,
    input tb_b0i_we_a,
    input [9:0] tb_b0i_addr_a,
    input [DW-1:0] tb_b0i_din_a,
    output [DW-1:0] tb_b0i_dout_a,
    input tb_b0i_en_b,
    input tb_b0i_we_b,
    input [9:0] tb_b0i_addr_b,
    input [DW-1:0] tb_b0i_din_b,
    output [DW-1:0] tb_b0i_dout_b,

    // bank1 real
    input tb_b1r_en_a,
    input tb_b1r_we_a,
    input [9:0] tb_b1r_addr_a,
    input [DW-1:0] tb_b1r_din_a,
    output [DW-1:0] tb_b1r_dout_a,

    input tb_b1r_en_b,
    input tb_b1r_we_b,
    input [9:0] tb_b1r_addr_b,
    input [DW-1:0] tb_b1r_din_b,
    output [DW-1:0] tb_b1r_dout_b,

    // bank1 imag
    input tb_b1i_en_a,
    input tb_b1i_we_a,
    input [9:0] tb_b1i_addr_a,
    input [DW-1:0] tb_b1i_din_a,
    output [DW-1:0] tb_b1i_dout_a,

    input tb_b1i_en_b,
    input tb_b1i_we_b,
    input [9:0] tb_b1i_addr_b,
    input [DW-1:0] tb_b1i_din_b,
    output [DW-1:0] tb_b1i_dout_b,

    // twi dreal
    input tb_twr_en,
    input tb_twr_we,
    input [8:0] tb_twr_addr,
    input [15:0] tb_twr_din,
    output [15:0] tb_twr_dout,

    //twidle imag
    input tb_twi_en,
    input tb_twi_we,
    input [8:0] tb_twi_addr,
    input [15:0] tb_twi_din,
    output [15:0] tb_twi_dout
);

    wire done_w;
    wire bank_sel; //for bank swithcing
    assign done = done_w;

    // ALL OF controller
    wire src_en_a, src_we_a, src_en_b, src_we_b;
    wire [9:0] src_addr_a, src_addr_b;
    wire dst_en_a, dst_we_a, dst_en_b, dst_we_b;
    wire [9:0] dst_addr_a, dst_addr_b;
    wire [DW-1:0] dst_din_a_re, dst_din_a_im;
    wire [DW-1:0] dst_din_b_re, dst_din_b_im;
    wire tw_en, tw_we;
    wire [8:0] tw_addr;
    wire [15:0] tw_din;

    // sram drve
    reg b0r_en_a_r, b0r_we_a_r, b0r_en_b_r, b0r_we_b_r;
    reg [9:0] b0r_addr_a_r, b0r_addr_b_r;
    reg [DW-1:0] b0r_din_a_r, b0r_din_b_r;
    reg b0i_en_a_r, b0i_we_a_r, b0i_en_b_r, b0i_we_b_r;
    reg [9:0] b0i_addr_a_r, b0i_addr_b_r;
    reg [DW-1:0] b0i_din_a_r, b0i_din_b_r;
    reg b1r_en_a_r, b1r_we_a_r, b1r_en_b_r, b1r_we_b_r;
    reg [9:0] b1r_addr_a_r, b1r_addr_b_r;
    reg [DW-1:0] b1r_din_a_r, b1r_din_b_r;
    reg b1i_en_a_r, b1i_we_a_r, b1i_en_b_r, b1i_we_b_r;
    reg [9:0] b1i_addr_a_r, b1i_addr_b_r;
    reg [DW-1:0] b1i_din_a_r, b1i_din_b_r;
//last twids
    reg twr_en_r, twr_we_r;
    reg [8:0] twr_addr_r;
    reg [15:0] twr_din_r;
    reg twi_en_r, twi_we_r;
    reg [8:0] twi_addr_r;
    reg [15:0] twi_din_r;

    // sram outputs
    wire [DW-1:0] b0r_qa, b0r_qb;
    wire [DW-1:0] b0i_qa, b0i_qb;
    wire [DW-1:0] b1r_qa, b1r_qb;
    wire [DW-1:0] b1i_qa, b1i_qb;
    wire [15:0] twr_q, twi_q;

    // sel back to contro
    wire [DW-1:0] src_dout_a_re, src_dout_a_im;
    wire [DW-1:0] src_dout_b_re, src_dout_b_im;
    wire [15:0] tw_dout_re, tw_dout_im;
//sram no worky :(
    reg b0r_en_a_pre, b0r_we_a_pre;
    reg [9:0] b0r_addr_a_pre;
    reg [DW-1:0] b0r_din_a_pre;

    reg b1r_en_a_pre, b1r_we_a_pre;
    reg [9:0] b1r_addr_a_pre;
    reg [DW-1:0] b1r_din_a_pre;

    reg b0i_en_a_pre, b0i_we_a_pre;
    reg [9:0] b0i_addr_a_pre;
    reg [DW-1:0] b0i_din_a_pre;

    reg b1i_en_a_pre, b1i_we_a_pre;
    reg [9:0] b1i_addr_a_pre;
    reg [DW-1:0] b1i_din_a_pre;

//b set
    reg b0r_en_b_pre, b0r_we_b_pre;
    reg [9:0] b0r_addr_b_pre;
    reg [DW-1:0] b0r_din_b_pre;

    reg b1r_en_b_pre, b1r_we_b_pre;
    reg [9:0] b1r_addr_b_pre;
    reg [DW-1:0] b1r_din_b_pre;

    reg b0i_en_b_pre, b0i_we_b_pre;
    reg [9:0] b0i_addr_b_pre;
    reg [DW-1:0] b0i_din_b_pre;

    reg b1i_en_b_pre, b1i_we_b_pre;
    reg [9:0] b1i_addr_b_pre;
    reg [DW-1:0] b1i_din_b_pre;
//twids
reg twr_en_pre, twr_we_pre;
reg [8:0] twr_addr_pre;
reg [15:0] twr_din_pre;

reg twi_en_pre, twi_we_pre;
reg [8:0] twi_addr_pre;
reg [15:0] twi_din_pre;
//slla sssign
    assign src_dout_a_re = (bank_sel == 1'b0) ? b0r_qa : b1r_qa;
    assign src_dout_a_im = (bank_sel == 1'b0) ? b0i_qa : b1i_qa;
    assign src_dout_b_re = (bank_sel == 1'b0) ? b0r_qb : b1r_qb;
    assign src_dout_b_im = (bank_sel == 1'b0) ? b0i_qb : b1i_qb;
    assign tw_dout_re = twr_q;
    assign tw_dout_im = twi_q;

    fft_controller u_ctrl (.clk(clk),.rst_n(rst_n),.start(start),.done(done_w),.src_en_a(src_en_a),.src_addr_a(src_addr_a),
.src_dout_a_re(src_dout_a_re),.src_dout_a_im(src_dout_a_im),
.src_en_b(src_en_b),.src_addr_b(src_addr_b),.src_dout_b_re(src_dout_b_re),.src_dout_b_im(src_dout_b_im),
.dst_en_a(dst_en_a),.dst_we_a(dst_we_a),.dst_addr_a(dst_addr_a),.dst_din_a_re(dst_din_a_re),.dst_din_a_im(dst_din_a_im),
.dst_en_b(dst_en_b),.dst_we_b(dst_we_b),.dst_addr_b(dst_addr_b),.dst_din_b_re(dst_din_b_re),.dst_din_b_im(dst_din_b_im),.tw_en(tw_en),
.tw_we(tw_we),.tw_addr(tw_addr),.tw_din(tw_din),.tw_dout_re(tw_dout_re),.tw_dout_im(tw_dout_im),.bank_sel(bank_sel)
    );
//for sram hold fix potentially
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        b0r_en_a_r <= 0; b0r_we_a_r <= 0; b0r_addr_a_r <= 0; b0r_din_a_r <= 0;
        b0r_en_b_r <= 0; b0r_we_b_r <= 0; b0r_addr_b_r <= 0; b0r_din_b_r <= 0;

        b0i_en_a_r <= 0; b0i_we_a_r <= 0; b0i_addr_a_r <= 0; b0i_din_a_r <= 0;
        b0i_en_b_r <= 0; b0i_we_b_r <= 0; b0i_addr_b_r <= 0; b0i_din_b_r <= 0;

        b1r_en_a_r <= 0; b1r_we_a_r <= 0; b1r_addr_a_r <= 0; b1r_din_a_r <= 0;
        b1r_en_b_r <= 0; b1r_we_b_r <= 0; b1r_addr_b_r <= 0; b1r_din_b_r <= 0;

        b1i_en_a_r <= 0; b1i_we_a_r <= 0; b1i_addr_a_r <= 0; b1i_din_a_r <= 0;
        b1i_en_b_r <= 0; b1i_we_b_r <= 0; b1i_addr_b_r <= 0; b1i_din_b_r <= 0;

        twr_en_r <= 0; twr_we_r <= 0; twr_addr_r <= 0; twr_din_r <= 0;
        twi_en_r <= 0; twi_we_r <= 0; twi_addr_r <= 0; twi_din_r <= 0;
    end else begin
        b0r_en_a_r <= b0r_en_a_pre; b0r_we_a_r <= b0r_we_a_pre; b0r_addr_a_r <= b0r_addr_a_pre; b0r_din_a_r <= b0r_din_a_pre;
        b0r_en_b_r <= b0r_en_b_pre; b0r_we_b_r <= b0r_we_b_pre; b0r_addr_b_r <= b0r_addr_b_pre; b0r_din_b_r <= b0r_din_b_pre;

        b0i_en_a_r <= b0i_en_a_pre; b0i_we_a_r <= b0i_we_a_pre; b0i_addr_a_r <= b0i_addr_a_pre; b0i_din_a_r <= b0i_din_a_pre;
        b0i_en_b_r <= b0i_en_b_pre; b0i_we_b_r <= b0i_we_b_pre; b0i_addr_b_r <= b0i_addr_b_pre; b0i_din_b_r <= b0i_din_b_pre;

        b1r_en_a_r <= b1r_en_a_pre; b1r_we_a_r <= b1r_we_a_pre; b1r_addr_a_r <= b1r_addr_a_pre; b1r_din_a_r <= b1r_din_a_pre;
        b1r_en_b_r <= b1r_en_b_pre; b1r_we_b_r <= b1r_we_b_pre; b1r_addr_b_r <= b1r_addr_b_pre; b1r_din_b_r <= b1r_din_b_pre;

        b1i_en_a_r <= b1i_en_a_pre; b1i_we_a_r <= b1i_we_a_pre; b1i_addr_a_r <= b1i_addr_a_pre; b1i_din_a_r <= b1i_din_a_pre;
        b1i_en_b_r <= b1i_en_b_pre; b1i_we_b_r <= b1i_we_b_pre; b1i_addr_b_r <= b1i_addr_b_pre; b1i_din_b_r <= b1i_din_b_pre;

        twr_en_r <= twr_en_pre; twr_we_r <= twr_we_pre; twr_addr_r <= twr_addr_pre; twr_din_r <= twr_din_pre;
        twi_en_r <= twi_en_pre; twi_we_r <= twi_we_pre; twi_addr_r <= twi_addr_pre; twi_din_r <= twi_din_pre;
    end
end
    // all sram signals assigning
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
/*
//real bank0 ab
            b0r_en_a_r <= 0; b0r_we_a_r <= 0; b0r_addr_a_r <= 0; b0r_din_a_r <= 0;
            b0r_en_b_r <= 0; b0r_we_b_r <= 0; b0r_addr_b_r <= 0; b0r_din_b_r <= 0;
//imag bank0 ab
            b0i_en_a_r <= 0; b0i_we_a_r <= 0; b0i_addr_a_r <= 0; b0i_din_a_r <= 0;
            b0i_en_b_r <= 0; b0i_we_b_r <= 0; b0i_addr_b_r <= 0; b0i_din_b_r <= 0;
//real ab bank1
            b1r_en_a_r <= 0; b1r_we_a_r <= 0; b1r_addr_a_r <= 0; b1r_din_a_r <= 0;
            b1r_en_b_r <= 0; b1r_we_b_r <= 0; b1r_addr_b_r <= 0; b1r_din_b_r <= 0;
//ab imag bank1
            b1i_en_a_r <= 0; b1i_we_a_r <= 0; b1i_addr_a_r <= 0; b1i_din_a_r <= 0;
            b1i_en_b_r <= 0; b1i_we_b_r <= 0; b1i_addr_b_r <= 0; b1i_din_b_r <= 0;
//twids
            twr_en_r   <= 0; twr_we_r   <= 0; twr_addr_r   <= 0; twr_din_r   <= 0;
            twi_en_r   <= 0; twi_we_r   <= 0; twi_addr_r   <= 0; twi_din_r   <= 0;
*/
		//real bank0 ab
		b0r_en_a_pre <= 0; b0r_we_a_pre <= 0; b0r_addr_a_pre <= 0; b0r_din_a_pre <= 0;
		b0r_en_b_pre <= 0; b0r_we_b_pre <= 0; b0r_addr_b_pre <= 0; b0r_din_b_pre <= 0;

		//imag bank0 ab
		b0i_en_a_pre <= 0; b0i_we_a_pre <= 0; b0i_addr_a_pre <= 0; b0i_din_a_pre <= 0;
		b0i_en_b_pre <= 0; b0i_we_b_pre <= 0; b0i_addr_b_pre <= 0; b0i_din_b_pre <= 0;

		//real ab bank1
		b1r_en_a_pre <= 0; b1r_we_a_pre <= 0; b1r_addr_a_pre <= 0; b1r_din_a_pre <= 0;
		b1r_en_b_pre <= 0; b1r_we_b_pre <= 0; b1r_addr_b_pre <= 0; b1r_din_b_pre <= 0;

		//ab imag bank1
		b1i_en_a_pre <= 0; b1i_we_a_pre <= 0; b1i_addr_a_pre <= 0; b1i_din_a_pre <= 0;
		b1i_en_b_pre <= 0; b1i_we_b_pre <= 0; b1i_addr_b_pre <= 0; b1i_din_b_pre <= 0;

		//twids
		twr_en_pre <= 0; twr_we_pre <= 0; twr_addr_pre <= 0; twr_din_pre <= 0;
		twi_en_pre <= 0; twi_we_pre <= 0; twi_addr_pre <= 0; twi_din_pre <= 0;

		end else if (tb_mode) begin
/*
		b0r_en_a_r <= tb_b0r_en_a; 
		b0r_we_a_r <= tb_b0r_we_a; 
		b0r_addr_a_r <= tb_b0r_addr_a; 
		b0r_din_a_r <= tb_b0r_din_a;
		b0r_en_b_r <= tb_b0r_en_b; 
		b0r_we_b_r <= tb_b0r_we_b; 
		b0r_addr_b_r <= tb_b0r_addr_b; 
		b0r_din_b_r <= tb_b0r_din_b;
		b0i_en_a_r <= tb_b0i_en_a; 
		b0i_we_a_r <= tb_b0i_we_a; 
		b0i_addr_a_r <= tb_b0i_addr_a; 
		b0i_din_a_r <= tb_b0i_din_a;
		b0i_en_b_r <= tb_b0i_en_b; 
		b0i_we_b_r <= tb_b0i_we_b; 
		b0i_addr_b_r <= tb_b0i_addr_b; 
		b0i_din_b_r <= tb_b0i_din_b;
		b1r_en_a_r <= tb_b1r_en_a; 
		b1r_we_a_r <= tb_b1r_we_a; 
		b1r_addr_a_r <= tb_b1r_addr_a; 
		b1r_din_a_r <= tb_b1r_din_a;
		b1r_en_b_r <= tb_b1r_en_b; 
		b1r_we_b_r <= tb_b1r_we_b; 
		b1r_addr_b_r <= tb_b1r_addr_b; 
		b1r_din_b_r <= tb_b1r_din_b;
		b1i_en_a_r <= tb_b1i_en_a; 
		b1i_we_a_r <= tb_b1i_we_a; 
		b1i_addr_a_r <= tb_b1i_addr_a; 
		b1i_din_a_r <= tb_b1i_din_a;
		b1i_en_b_r <= tb_b1i_en_b; 
		b1i_we_b_r <= tb_b1i_we_b; 
		b1i_addr_b_r <= tb_b1i_addr_b; 
		b1i_din_b_r <= tb_b1i_din_b;
		twr_en_r <= tb_twr_en;
		twr_we_r <= tb_twr_we;   
		twr_addr_r <= tb_twr_addr;   
		twr_din_r <= tb_twr_din;
		twi_en_r <= tb_twi_en;
		twi_we_r <= tb_twi_we;
		twi_addr_r <= tb_twi_addr;
		twi_din_r <= tb_twi_din;
*/
		b0r_en_a_pre <= tb_b0r_en_a;
		b0r_we_a_pre <= tb_b0r_we_a;
		b0r_addr_a_pre <= tb_b0r_addr_a;
		b0r_din_a_pre <= tb_b0r_din_a;

		b0r_en_b_pre <= tb_b0r_en_b;
		b0r_we_b_pre <= tb_b0r_we_b;
		b0r_addr_b_pre <= tb_b0r_addr_b;
		b0r_din_b_pre <= tb_b0r_din_b;

		b0i_en_a_pre <= tb_b0i_en_a;
		b0i_we_a_pre <= tb_b0i_we_a;
		b0i_addr_a_pre <= tb_b0i_addr_a;
		b0i_din_a_pre <= tb_b0i_din_a;

		b0i_en_b_pre <= tb_b0i_en_b;
		b0i_we_b_pre <= tb_b0i_we_b;
		b0i_addr_b_pre <= tb_b0i_addr_b;
		b0i_din_b_pre <= tb_b0i_din_b;

		b1r_en_a_pre <= tb_b1r_en_a;
		b1r_we_a_pre <= tb_b1r_we_a;
		b1r_addr_a_pre <= tb_b1r_addr_a;
		b1r_din_a_pre <= tb_b1r_din_a;

		b1r_en_b_pre <= tb_b1r_en_b;
		b1r_we_b_pre <= tb_b1r_we_b;
		b1r_addr_b_pre <= tb_b1r_addr_b;
		b1r_din_b_pre <= tb_b1r_din_b;

		b1i_en_a_pre <= tb_b1i_en_a;
		b1i_we_a_pre <= tb_b1i_we_a;
		b1i_addr_a_pre <= tb_b1i_addr_a;
		b1i_din_a_pre <= tb_b1i_din_a;

		b1i_en_b_pre <= tb_b1i_en_b;
		b1i_we_b_pre <= tb_b1i_we_b;
		b1i_addr_b_pre <= tb_b1i_addr_b;
		b1i_din_b_pre <= tb_b1i_din_b;

		twr_en_pre <= tb_twr_en;
		twr_we_pre <= tb_twr_we;
		twr_addr_pre <= tb_twr_addr;
		twr_din_pre <= tb_twr_din;

		twi_en_pre <= tb_twi_en;
		twi_we_pre <= tb_twi_we;
		twi_addr_pre <= tb_twi_addr;
		twi_din_pre <= tb_twi_din;
        end else begin
            // bank0 real
/*
            b0r_en_a_r<= (bank_sel == 1'b0) ? src_en_a: dst_en_a;
            b0r_we_a_r<= (bank_sel == 1'b0) ? src_we_a: dst_we_a;
            b0r_addr_a_r <= (bank_sel == 1'b0) ? src_addr_a : dst_addr_a;
            b0r_din_a_r <= (bank_sel == 1'b0) ? {DW{1'b0}}: dst_din_a_re;

            b0r_en_b_r <= (bank_sel == 1'b0) ? src_en_b: dst_en_b;
            b0r_we_b_r <= (bank_sel == 1'b0) ? src_we_b: dst_we_b;
            b0r_addr_b_r <= (bank_sel == 1'b0) ? src_addr_b : dst_addr_b;
            b0r_din_b_r <= (bank_sel == 1'b0) ? {DW{1'b0}}: dst_din_b_re;
*/
            b0r_en_a_pre<= (bank_sel == 1'b0) ?  src_en_a : dst_en_a;
            b0r_we_a_pre<= (bank_sel == 1'b0) ? 1'b0: dst_we_a;
            b0r_addr_a_pre <= (bank_sel == 1'b0) ? src_addr_a : dst_addr_a;
            b0r_din_a_pre <= (bank_sel == 1'b0) ? {DW{1'b0}}: dst_din_a_re;

            b0r_en_b_pre <= (bank_sel == 1'b0) ? src_en_b: dst_en_b;
            b0r_we_b_pre <= (bank_sel == 1'b0) ? 1'b0: dst_we_b;
            b0r_addr_b_pre <= (bank_sel == 1'b0) ? src_addr_b : dst_addr_b;
            b0r_din_b_pre <= (bank_sel == 1'b0) ? {DW{1'b0}}: dst_din_b_re;

            // bank0 imag
/*
            b0i_en_a_r <= (bank_sel == 1'b0) ? src_en_a : dst_en_a;
            b0i_we_a_r <= (bank_sel == 1'b0) ? src_we_a : dst_we_a;
            b0i_addr_a_r <= (bank_sel == 1'b0) ? src_addr_a : dst_addr_a;
            b0i_din_a_r <= (bank_sel == 1'b0) ? {DW{1'b0}} : dst_din_a_im;

            b0i_en_b_r <= (bank_sel == 1'b0) ? src_en_b : dst_en_b;
            b0i_we_b_r <= (bank_sel == 1'b0) ? src_we_b : dst_we_b;
            b0i_addr_b_r <= (bank_sel == 1'b0) ? src_addr_b : dst_addr_b;
            b0i_din_b_r <= (bank_sel == 1'b0) ? {DW{1'b0}} : dst_din_b_im;
*/
            b0i_en_a_pre <= (bank_sel == 1'b0) ? src_en_a : dst_en_a;
            b0i_we_a_pre <= (bank_sel == 1'b0) ? 1'b0 : dst_we_a;
            b0i_addr_a_pre <= (bank_sel == 1'b0) ? src_addr_a : dst_addr_a;
            b0i_din_a_pre <= (bank_sel == 1'b0) ? {DW{1'b0}} : dst_din_a_im;

            b0i_en_b_pre <= (bank_sel == 1'b0) ? src_en_b : dst_en_b;
            b0i_we_b_pre <= (bank_sel == 1'b0) ? 1'b0 : dst_we_b;
            b0i_addr_b_pre <= (bank_sel == 1'b0) ? src_addr_b : dst_addr_b;
            b0i_din_b_pre <= (bank_sel == 1'b0) ? {DW{1'b0}} : dst_din_b_im;

            // bank1 real
/*
            b1r_en_a_r <= (bank_sel == 1'b1) ? src_en_a : dst_en_a;
            b1r_we_a_r <= (bank_sel == 1'b1) ? src_we_a : dst_we_a;
            b1r_addr_a_r <= (bank_sel == 1'b1) ? src_addr_a : dst_addr_a;
            b1r_din_a_r <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_a_re;

            b1r_en_b_r <= (bank_sel == 1'b1) ? src_en_b : dst_en_b;
            b1r_we_b_r <= (bank_sel == 1'b1) ? src_we_b : dst_we_b;
            b1r_addr_b_r <= (bank_sel == 1'b1) ? src_addr_b : dst_addr_b;
            b1r_din_b_r <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_b_re;
*/
            b1r_en_a_pre <= (bank_sel == 1'b1) ? src_en_a : dst_en_a;
            b1r_we_a_pre <= (bank_sel == 1'b1) ? 1'b0 : dst_we_a;
            b1r_addr_a_pre <= (bank_sel == 1'b1) ? src_addr_a : dst_addr_a;
            b1r_din_a_pre <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_a_re;

            b1r_en_b_pre <= (bank_sel == 1'b1) ? src_en_b : dst_en_b;
            b1r_we_b_pre <= (bank_sel == 1'b1) ? 1'b0 : dst_we_b;
            b1r_addr_b_pre <= (bank_sel == 1'b1) ? src_addr_b : dst_addr_b;
            b1r_din_b_pre <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_b_re;
            // bank1 imag
/*
            b1i_en_a_r <= (bank_sel == 1'b1) ? src_en_a : dst_en_a;
            b1i_we_a_r <= (bank_sel == 1'b1) ? src_we_a : dst_we_a;
            b1i_addr_a_r <= (bank_sel == 1'b1) ? src_addr_a : dst_addr_a;
            b1i_din_a_r <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_a_im;

            b1i_en_b_r <= (bank_sel == 1'b1) ? src_en_b : dst_en_b;
            b1i_we_b_r <= (bank_sel == 1'b1) ? src_we_b : dst_we_b;
            b1i_addr_b_r <= (bank_sel == 1'b1) ? src_addr_b : dst_addr_b;
            b1i_din_b_r <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_b_im;
*/
            b1i_en_a_pre <= (bank_sel == 1'b1) ? src_en_a : dst_en_a;
            b1i_we_a_pre <= (bank_sel == 1'b1) ? 1'b0 : dst_we_a;
            b1i_addr_a_pre <= (bank_sel == 1'b1) ? src_addr_a : dst_addr_a;
            b1i_din_a_pre <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_a_im;

            b1i_en_b_pre <= (bank_sel == 1'b1) ? src_en_b : dst_en_b;
            b1i_we_b_pre <= (bank_sel == 1'b1) ? 1'b0 : dst_we_b;
            b1i_addr_b_pre <= (bank_sel == 1'b1) ? src_addr_b : dst_addr_b;
            b1i_din_b_pre <= (bank_sel == 1'b1) ? {DW{1'b0}} : dst_din_b_im;
            // twid
/*
            twr_en_r <= tw_en;
            twr_we_r <= tw_we;
            twr_addr_r <= tw_addr;
            twr_din_r <= tw_din;

            twi_en_r <= tw_en;
            twi_we_r <= tw_we;
            twi_addr_r <= tw_addr;
            twi_din_r <= tw_din;
*/
            twr_en_pre <= tw_en;
            twr_we_pre <= tw_we;
            twr_addr_pre <= tw_addr;
            twr_din_pre <= tw_din;

            twi_en_pre <= tw_en;
            twi_we_pre <= tw_we;
            twi_addr_pre <= tw_addr;
            twi_din_pre <= tw_din;
        end
    end

    sram_real_bank0_wrapper real0u (
        .clk_a (clk), .en_a (b0r_en_a_r), .we_a (b0r_we_a_r), .addr_a (b0r_addr_a_r), .din_a (b0r_din_a_r), .dout_a (b0r_qa),
        .clk_b (clk), .en_b (b0r_en_b_r), .we_b (b0r_we_b_r), .addr_b (b0r_addr_b_r), .din_b (b0r_din_b_r), .dout_b (b0r_qb));

    sram_imag_bank0_wrapper imag0u (
        .clk_a (clk), .en_a (b0i_en_a_r), .we_a (b0i_we_a_r), .addr_a (b0i_addr_a_r), .din_a (b0i_din_a_r), .dout_a (b0i_qa),
        .clk_b (clk), .en_b (b0i_en_b_r), .we_b (b0i_we_b_r), .addr_b (b0i_addr_b_r), .din_b (b0i_din_b_r), .dout_b (b0i_qb));

    sram_real_bank1_wrapper real1u (
        .clk_a (clk), .en_a (b1r_en_a_r), .we_a (b1r_we_a_r), .addr_a (b1r_addr_a_r), .din_a (b1r_din_a_r), .dout_a (b1r_qa),
        .clk_b (clk), .en_b (b1r_en_b_r), .we_b (b1r_we_b_r), .addr_b (b1r_addr_b_r), .din_b (b1r_din_b_r), .dout_b (b1r_qb));

    sram_imag_bank1_wrapper imag1u (
        .clk_a (clk), .en_a (b1i_en_a_r), .we_a (b1i_we_a_r), .addr_a (b1i_addr_a_r), .din_a (b1i_din_a_r), .dout_a (b1i_qa),
        .clk_b (clk), .en_b (b1i_en_b_r), .we_b (b1i_we_b_r), .addr_b (b1i_addr_b_r), .din_b (b1i_din_b_r), .dout_b (b1i_qb));

    twiddle_bank0_wrapper twidreal (
        .clk(clk), .en(twr_en_r), .we(twr_we_r), .addr(twr_addr_r), .din(twr_din_r), .dout(twr_q));

    twiddle_bank1_wrapper twidimag (
        .clk(clk), .en(twi_en_r), .we(twi_we_r), .addr(twi_addr_r), .din(twi_din_r), .dout(twi_q));

    assign tb_b0r_dout_a = b0r_qa;
    assign tb_b0r_dout_b = b0r_qb;
    assign tb_b0i_dout_a = b0i_qa;
    assign tb_b0i_dout_b = b0i_qb;
    assign tb_b1r_dout_a = b1r_qa;
    assign tb_b1r_dout_b = b1r_qb;
    assign tb_b1i_dout_a = b1i_qa;
    assign tb_b1i_dout_b = b1i_qb;
    assign tb_twr_dout = twr_q;
    assign tb_twi_dout = twi_q;

endmodule
