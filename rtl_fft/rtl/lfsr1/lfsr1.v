`timescale 1ns/1ps

module lfsr1 (input  wire clk,input  wire resetn,input  wire wen,input  wire [15:0] seed,output reg  [15:0] lfsr_out
);

    wire [15:0] lfsr_next;

    assign lfsr_next = {lfsr_out[14:0],
                        lfsr_out[15] ^ lfsr_out[12] ^ lfsr_out[5] ^ lfsr_out[0]};

    always @(posedge clk) begin
        if (!resetn)
            lfsr_out <= (seed == 16'h0000) ? 16'h0001 : seed;
        else if (wen)
            lfsr_out <= lfsr_next;
    end

endmodule
