`timescale 1ns/1ps

module fft_addr_gen (input [3:0] stage,input [8:0] butterfly_idx,output reg [9:0] a_addr,output reg [9:0] b_addr,output reg [8:0] tw_addr);

    reg [9:0] half; //spacinmg for butterfly
    reg [10:0] m; //size of the fft group
    reg [8:0] j;
    reg [8:0] group;
    reg [10:0] base; //starting addres
    reg [10:0] stride; //fft step seiz
//a = X(base + j) and b = X(base + j + half)
    always @(*) begin
        half = (10'd1 << stage);
        m = (11'd1 << (stage + 1));
        stride = (11'd1024 >> (stage + 1));

        group = butterfly_idx >> stage;
        j = butterfly_idx & (half - 1);

        base = group * m;
        a_addr = base + j;
        b_addr = base + j + half;
        tw_addr = j * stride;
    end
/*always @(*) begin
    if (stage == 4'd3 && butterfly_idx >= 9'd428 && butterfly_idx <= 9'd435)
        $display(" from addrgen stage %0d idx %0d half %0d j %0d stride %0d a %0d b %0d tw %0d", stage, butterfly_idx, half, j, stride, a_addr, b_addr, tw_addr);
end */
endmodule
