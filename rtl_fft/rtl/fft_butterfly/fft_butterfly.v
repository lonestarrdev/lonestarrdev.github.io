`timescale 1ns/1ps

module fft_butterfly #(
    parameter dw = 24,
    parameter tw = 16
)( //inputs
    input signed [dw-1:0]a_re,
    input signed [dw-1:0]a_im,
    input signed [dw-1:0]b_re,
    input signed [dw-1:0]b_im,
    input signed [tw-1:0]w_re,
    input signed [tw-1:0]w_im,
    input [3:0] stage,

    output signed [dw-1:0]y0_re,
    output signed [dw-1:0]y0_im,
    output signed [dw-1:0]y1_re,
    output signed [dw-1:0]y1_im
);

    wire signed [dw+tw-1:0]bw_re_re, bw_im_im, bw_re_im, bw_im_re;
    wire signed [dw+tw:0] twiddled_b_re_wide, twiddled_b_im_wide;
    wire signed [dw:0] twiddled_b_re, twiddled_b_im;
    wire signed [dw:0] out0_re_wide, out0_im_wide, out1_re_wide, out1_im_wide;
    wire signed [dw:0] out0_re_scaled, out0_im_scaled, out1_re_scaled, out1_im_scaled;
    wire do_scale;
	//rounding func may delete if not needed?
    function signed [dw:0]round_q15;
        input signed [dw+tw:0]x;
        reg signed [dw+tw:0]bias;
        begin
            if (x[dw+tw])
                bias = -($signed(1) <<< (tw-2));
            else
                bias =($signed(1) <<< (tw-2));

            round_q15 =(x + bias) >>> (tw-1);
        end
    endfunction
//output sat func
//added bc truncation was killing itself and killing me
    function signed [dw-1:0]satdw;
        input signed [dw:0]x;
        begin
            if (x > $signed({1'b0, {(dw-1){1'b1}}}))
                satdw = {1'b0, {(dw-1){1'b1}}};
            else if (x < -($signed(1'b1) <<< (dw-1)))
                satdw = {1'b1, {(dw-1){1'b0}}};
            else
                satdw = x[dw-1:0];
        end
    endfunction
//multiplication for butterfly
    assign bw_re_re = b_re * w_re;
    assign bw_im_im = b_im * w_im;
    assign bw_re_im = b_re * w_im;
    assign bw_im_re = b_im * w_re;
    assign twiddled_b_re_wide = bw_re_re - bw_im_im;
    assign twiddled_b_im_wide = bw_re_im + bw_im_re;
// integer k;
    assign twiddled_b_re = round_q15(twiddled_b_re_wide);
    assign twiddled_b_im = round_q15(twiddled_b_im_wide);
    assign out0_re_wide = a_re + twiddled_b_re;
    assign out0_im_wide = a_im + twiddled_b_im;
    assign out1_re_wide = a_re - twiddled_b_re;
    assign out1_im_wide = a_im - twiddled_b_im;
    assign do_scale = 1'b0;
//assign do_scale = (stage >= 4'd8);
// always @(*) begin
//     if (stage == 4'd9) begin
//     end
// end
//scaling for overflow
//solved with expadning to 24 btis
    assign out0_re_scaled = do_scale ? (out0_re_wide >>> 1) : out0_re_wide;
    assign out0_im_scaled = do_scale ? (out0_im_wide >>>1) : out0_im_wide;
    assign out1_re_scaled = do_scale ? (out1_re_wide >>> 1) : out1_re_wide;
    assign out1_im_scaled = do_scale ? (out1_im_wide >>> 1) : out1_im_wide;
    assign y0_re = out0_re_scaled[dw-1:0];
    assign y0_im = out0_im_scaled[dw-1:0];
    assign y1_re = out1_re_scaled[dw-1:0];
    assign y1_im = out1_im_scaled[dw-1:0];
    // assign y0_re = satdw(out0_re_scaled);
    // assign y0_im = satdw(out0_im_scaled);
    // assign y1_re = satdw(out1_re_scaled);
    // assign y1_im = satdw(out1_im_scaled);

endmodule
