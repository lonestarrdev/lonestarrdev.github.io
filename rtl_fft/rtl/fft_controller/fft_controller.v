`timescale 1ns/1ps

module fft_controller #(parameter DW = 24)(
    input clk,
    input rst_n,
    input start,
    output reg done,

    output reg src_en_a,
    output reg [9:0] src_addr_a,
    input [DW-1:0] src_dout_a_re,
    input [DW-1:0] src_dout_a_im,
    output reg src_en_b,
    output reg [9:0] src_addr_b,
    input [DW-1:0] src_dout_b_re,
    input [DW-1:0] src_dout_b_im,

    output reg dst_en_a,
    output reg dst_we_a,
    output reg [9:0] dst_addr_a,
    output reg [DW-1:0] dst_din_a_re,
    output reg [DW-1:0] dst_din_a_im,
    output reg dst_en_b,
    output reg dst_we_b,
    output reg [9:0] dst_addr_b,
    output reg [DW-1:0] dst_din_b_re,
    output reg [DW-1:0] dst_din_b_im,

    output reg tw_en,
    output reg tw_we,
    output reg [8:0] tw_addr,
    output reg [15:0] tw_din,
    input [15:0] tw_dout_re,
    input [15:0] tw_dout_im,
    output reg bank_sel
);
//states
/*
    localparam S_IDLE = 3'd0;
    localparam S_RD_REQ = 3'd1;
    localparam S_RD_WAIT0 = 3'd2;
    localparam S_RD_WAIT1 = 3'd3;
    localparam S_LATCH = 3'd4;
    localparam S_WR_REQ = 3'd5;
    localparam S_WR_WAIT  = 3'd6;
    localparam S_ADV = 3'd7;*/
	localparam S_IDLE     = 4'd0;
	localparam S_RD_REQ   = 4'd1;
	localparam S_RD_WAIT0 = 4'd2;
	localparam S_RD_WAIT1 = 4'd3;
	localparam S_RD_WAIT2 = 4'd4;
	localparam S_LATCH    = 4'd5;
	localparam S_WR_REQ   = 4'd6;
	localparam S_WR_WAIT = 4'd7;
	localparam S_WR_WAIT1 = 4'd8;
	localparam S_ADV      = 4'd9;

reg [3:0] state, next_state;

 //   reg [2:0] state, next_state;
//stages for scaling down
    reg [3:0] stage;
    reg [8:0] butterfly_idx;

    wire [9:0] a_addr;
    wire [9:0] b_addr;
    wire [8:0] tw_addr_w;

    reg signed [DW-1:0] a_re_reg, a_im_reg;
    reg signed [DW-1:0] b_re_reg, b_im_reg;
    reg signed [15:0] w_re_reg, w_im_reg;
	reg [9:0] a_addr_req_reg, b_addr_req_reg;
	reg [8:0] tw_addr_req_reg;
    wire signed [DW-1:0] y0_re, y0_im, y1_re, y1_im;

    wire last_bfly  = (butterfly_idx == 9'd511);
    wire last_stage = (stage == 4'd9);

    fft_addr_gen addrgeninst (.stage(stage),.butterfly_idx(butterfly_idx),.a_addr(a_addr),.b_addr(b_addr),.tw_addr(tw_addr_w));

    fft_butterfly #(.dw(DW),.tw(16)) butterflyinst (
        .stage(stage),.a_re(a_re_reg),.a_im(a_im_reg),.b_re(b_re_reg),.b_im(b_im_reg),.w_re(w_re_reg),.w_im(w_im_reg),.y0_re(y0_re),.y0_im(y0_im),
        .y1_re(y1_re),.y1_im(y1_im));
//reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end
//next state logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: if (start) next_state = S_RD_REQ;
            S_RD_REQ: next_state = S_RD_WAIT0;
            S_RD_WAIT0: next_state = S_RD_WAIT1;
            S_RD_WAIT1: next_state = S_RD_WAIT2;
	    S_RD_WAIT2: next_state = S_LATCH;
            S_LATCH: next_state = S_WR_REQ;
            S_WR_REQ: next_state = S_WR_WAIT;
            S_WR_WAIT: next_state = S_WR_WAIT1;
	    S_WR_WAIT1: next_state = S_ADV;
            S_ADV: if (last_stage && last_bfly) next_state = S_IDLE;
                        else next_state = S_RD_REQ;
            default: next_state = S_IDLE;
        endcase
    end
//state variable states
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage <= 4'd0;
            butterfly_idx <= 9'd0;
            bank_sel <= 1'b0;
            done <= 1'b0;

            a_re_reg <= {DW{1'b0}};
            a_im_reg <= {DW{1'b0}};
            b_re_reg <= {DW{1'b0}};
            b_im_reg <= {DW{1'b0}};
            w_re_reg <= 16'sd0;
            w_im_reg <= 16'sd0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        stage <= 4'd0;
                        butterfly_idx <= 9'd0;
                        bank_sel <= 1'b0;
                    end
                end

                S_LATCH: begin
                    a_re_reg <= src_dout_a_re;
                    a_im_reg <= src_dout_a_im;
                    b_re_reg <= src_dout_b_re;
                    b_im_reg <= src_dout_b_im;
                    w_re_reg <= tw_dout_re;
                    w_im_reg <= tw_dout_im;
                end

                S_ADV: begin
                    if (last_bfly) begin
                        butterfly_idx <= 9'd0;
                        if (last_stage) begin
                            done <= 1'b1;
                        end else begin
                            stage <= stage + 4'd1;
                            bank_sel <= ~bank_sel;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 9'd1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        src_en_a = 1'b0;
        src_addr_a = 10'd0;

        src_en_b = 1'b0;
        src_addr_b = 10'd0;

        dst_en_a = 1'b0;
        dst_we_a = 1'b0;
        dst_addr_a = 10'd0;
        dst_din_a_re = {DW{1'b0}};
        dst_din_a_im = {DW{1'b0}};

        dst_en_b = 1'b0;
        dst_we_b = 1'b0;
        dst_addr_b = 10'd0;
        dst_din_b_re = {DW{1'b0}};
        dst_din_b_im = {DW{1'b0}};

        tw_en = 1'b0;
        tw_we = 1'b0;
        tw_addr = 9'd0;
        tw_din = 16'd0;

        case (state)
	S_RD_REQ: begin
	    a_addr_req_reg <= a_addr;
	    b_addr_req_reg <= b_addr;
	    tw_addr_req_reg <= tw_addr_w;
		end
            S_RD_WAIT0,
            S_RD_WAIT1,
	    S_RD_WAIT2,
            S_LATCH: begin
                src_en_a = 1'b1;
                src_addr_a = a_addr;

                src_en_b = 1'b1;
                src_addr_b = b_addr;

                tw_en = 1'b1;
                tw_we = 1'b0;
                tw_addr = tw_addr_w;
            end

            S_WR_REQ, S_WR_WAIT: begin
                dst_en_a = 1'b1;
                dst_we_a = 1'b1;
                dst_addr_a = a_addr;
                dst_din_a_re = y0_re;
                dst_din_a_im = y0_im;

                dst_en_b = 1'b1;
                dst_we_b = 1'b1;
                dst_addr_b = b_addr;
                dst_din_b_re = y1_re;
                dst_din_b_im = y1_im;
            end
		S_WR_WAIT1: begin
		end
        endcase
    end
//jesus christ this took way too long
endmodule
