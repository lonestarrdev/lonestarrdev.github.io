`timescale 1ns/1ps

module fft_controller #(
    parameter DW = 24
)(
    input clk,
    input rst_n,
    input start,
    output reg done,

    //databank init read 
    output reg src_en_a,
    output reg src_we_a,
    output reg [9:0]  src_addr_a,
    output reg [DW-1:0] src_din_a,
    input [DW-1:0] src_dout_a_re,
    input [DW-1:0] src_dout_a_im,

    output reg src_en_b,
    output reg src_we_b,
    output reg [9:0]  src_addr_b,
    output reg [DW-1:0] src_din_b,
    input [DW-1:0] src_dout_b_re,
    input [DW-1:0] src_dout_b_im,

    // actual databank write stuff
    output reg dst_en_a,
    output reg dst_we_a,
    output reg [9:0]  dst_addr_a,
    output reg [DW-1:0] dst_din_a_re,
    output reg [DW-1:0] dst_din_a_im,

    output reg dst_en_b,
    output reg dst_we_b,
    output reg [9:0]  dst_addr_b,
    output reg [DW-1:0] dst_din_b_re,
    output reg [DW-1:0] dst_din_b_im,

    //twid
    output reg tw_en,
    output reg tw_we,
    output reg [8:0]  tw_addr,
    output reg [15:0] tw_din,
    input [15:0] tw_dout_re,
    input [15:0] tw_dout_im,
    output reg        bank_sel
);

    localparam S_IDLE         = 3'd0;
    localparam S_READ_SETUP   = 3'd1;
    localparam S_READ_WAIT    = 3'd2;
    localparam S_READ_CAPTURE = 3'd3;
    localparam S_WRITE_SETUP  = 3'd4;
    localparam S_WRITE_HOLD   = 3'd5;
    localparam S_NEXT         = 3'd6;
    localparam S_DONE         = 3'd7;

    reg [2:0] state, next_state;

    reg [3:0] stage;
    reg [8:0] butterfly_idx;

    wire [9:0] a_addr;
    wire [9:0] b_addr;
    wire [8:0] tw_addr_w;

    reg signed [DW-1:0] a_re_reg, a_im_reg;
    reg signed [DW-1:0] b_re_reg, b_im_reg;
    reg signed [15:0] w_re_reg, w_im_reg;

    wire signed [DW-1:0] y0_re, y0_im, y1_re, y1_im;

    fft_addr_gen u_addr_gen (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .tw_addr(tw_addr_w)
    );

fft_butterfly #(
    .DW(DW),
    .TW(16)
)	u_bfly (
	.stage(stage),
        .a_re(a_re_reg),
        .a_im(a_im_reg),
        .b_re(b_re_reg),
        .b_im(b_im_reg),
        .w_re(w_re_reg),
        .w_im(w_im_reg),
        .y0_re(y0_re),
        .y0_im(y0_im),
        .y1_re(y1_re),
        .y1_im(y1_im)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:         if (start) next_state = S_READ_SETUP;
            S_READ_SETUP:   next_state = S_READ_WAIT;
            S_READ_WAIT:    next_state = S_READ_CAPTURE;
            S_READ_CAPTURE: next_state = S_WRITE_SETUP;
            S_WRITE_SETUP:  next_state = S_WRITE_HOLD;
            S_WRITE_HOLD:   next_state = S_NEXT;
            S_NEXT: begin
                if (stage == 4'd9 && butterfly_idx == 9'd511)
                    next_state = S_DONE;
                else
                    next_state = S_READ_SETUP;
            end
            S_DONE:         next_state = S_IDLE;
            default:        next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage         <= 4'd0;
            butterfly_idx <= 9'd0;
            done          <= 1'b0;
            bank_sel      <= 1'b0;

            a_re_reg      <= {DW{1'b0}};
            a_im_reg      <= {DW{1'b0}};
            b_re_reg      <= {DW{1'b0}};
            b_im_reg      <= {DW{1'b0}};
            w_re_reg      <= 16'sd0;
            w_im_reg      <= 16'sd0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        stage         <= 4'd0;
                        butterfly_idx <= 9'd0;
                        bank_sel      <= 1'b0;
                    end
                end

                S_READ_CAPTURE: begin
                    a_re_reg <= src_dout_a_re;
                    a_im_reg <= src_dout_a_im;
                    b_re_reg <= src_dout_b_re;
                    b_im_reg <= src_dout_b_im;
                    w_re_reg <= tw_dout_re;
                    w_im_reg <= tw_dout_im;
if (stage == 4'd0 && butterfly_idx < 10) begin
    $display("READDBG stage=%0d bfly=%0d a_addr=%0d b_addr=%0d srcA=(%0d,%0d) srcB=(%0d,%0d)",
             stage, butterfly_idx, a_addr, b_addr,
             $signed(src_dout_a_re), $signed(src_dout_a_im),
             $signed(src_dout_b_re), $signed(src_dout_b_im));
end
/*
$display("at readcap stage=%0d idx=%0d a=%h+j%h b=%h+j%h w=%h+j%h",
         stage, butterfly_idx,
         src_dout_a_re, src_dout_a_im,
         src_dout_b_re, src_dout_b_im,
         tw_dout_re, tw_dout_im);*/
/*
$display("stage %0d ind %0d twaddr %0d w %h+j%h",
         stage, butterfly_idx, tw_addr_w, tw_dout_re, tw_dout_im);*/
                end

                S_NEXT: begin
                    if (butterfly_idx == 9'd511) begin
/*
    			$display("stage done, oldstage %0d newstg %0d banksel %0d", stage, stage+1, ~bank_sel); */
                        butterfly_idx <= 9'd0;
                        if (stage != 4'd9) begin
                            stage    <= stage + 4'd1;
                            bank_sel <= ~bank_sel;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 9'd1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin
        src_en_a     = 1'b0;
        src_we_a     = 1'b0;
        src_addr_a   = 10'd0;
        src_din_a    = {DW{1'b0}};

        src_en_b     = 1'b0;
        src_we_b     = 1'b0;
        src_addr_b   = 10'd0;
        src_din_b    = {DW{1'b0}};

        dst_en_a     = 1'b0;
        dst_we_a     = 1'b0;
        dst_addr_a   = 10'd0;
        dst_din_a_re = {DW{1'b0}};
        dst_din_a_im = {DW{1'b0}};

        dst_en_b     = 1'b0;
        dst_we_b     = 1'b0;
        dst_addr_b   = 10'd0;
        dst_din_b_re = {DW{1'b0}};
        dst_din_b_im = {DW{1'b0}};

        tw_en        = 1'b0;
        tw_we        = 1'b0;
        tw_addr      = 9'd0;
        tw_din       = 16'd0;

        case (state)
            S_READ_SETUP,
            S_READ_WAIT,
            S_READ_CAPTURE: begin
                src_en_a   = 1'b1;
                src_we_a   = 1'b0;
                src_addr_a = a_addr;

                src_en_b   = 1'b1;
                src_we_b   = 1'b0;
                src_addr_b = b_addr;

                tw_en      = 1'b1;
                tw_we      = 1'b0;
                tw_addr    = tw_addr_w;
            end

            S_WRITE_SETUP,
            S_WRITE_HOLD: begin
/*if (state == S_WRITE_HOLD && stage == 4'd9 && butterfly_idx >= 9'd508)
    $display("finalwrite idx=%0d a_addr=%0d y0=%h+j%h b_addr=%0d y1=%h+j%h bank_sel=%0d",
             butterfly_idx, a_addr, y0_re, y0_im, b_addr, y1_re, y1_im, bank_sel);
if (state == S_WRITE_HOLD) begin
    $display("write stage=%0d idx=%0d a_addr=%0d y0=%h+j%h b_addr=%0d y1=%h+j%h",

             stage, butterfly_idx, 
             a_addr, y0_re, y0_im,
             b_addr, y1_re, y1_im);
end*/
                dst_en_a     = 1'b1;
                dst_we_a     = 1'b1;
                dst_addr_a   = a_addr;
                dst_din_a_re = y0_re;
                dst_din_a_im = y0_im;

                dst_en_b     = 1'b1;
                dst_we_b     = 1'b1;
                dst_addr_b   = b_addr;
                dst_din_b_re = y1_re;
                dst_din_b_im = y1_im;
            end
        endcase
    end

endmodule
