module cmem (input wire clk,input wire rstn, input wire cload, input wire [5:0] caddr, input wire signed [15:0] cin, input wire [5:0] coef_read_addr,output reg signed [15:0] coef_out);
  reg signed [15:0] mem [0:63];
  integer count;

  always @(negedge rstn or posedge clk) 
    begin
      if (!rstn)
        begin
          for (count = 0; count < 64; count = count + 1)
            mem[count] <= 16'sd0;
          coef_out <= 16'sd0;
        end 
      else 
        begin
          if (cload)
            mem[caddr] <= cin;
          coef_out <= mem[coef_read_addr];
        end
    end
endmodule


