`timescale 1ns/1ps

module regfile (input wire clk,input wire rstn,input wire write_en,input wire [5:0] write_addr,input wire signed [15:0] write_data, input wire [5:0] read_addr, output reg  signed [15:0] out_data);

  reg signed [15:0] mem [0:63];
  integer count;

  always @(negedge rstn or posedge clk) 
    begin
      if (!rstn) 
        begin
          for (count = 0; count < 64; count = count + 1)
            mem[count] <= 16'sd0;
          out_data <= 16'sd0;
          end 
      else 
        begin
          if (write_en)
            mem[write_addr] <= write_data;
          out_data <= mem[read_addr];
        end
    end

endmodule

