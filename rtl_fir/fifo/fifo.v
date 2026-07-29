`timescale 1ns/1ps

module fifo(input wclk, input rclk, input rstn, input[15:0]wdata, input wvalid, input rd_en, output wfull, output rempty, output reg[15:0]rdata, output reg rvalid);

  reg[15:0] mem[0:7];
  reg[3:0] writeptr_bin, writeptr, readptr_bin, readptr, writeq1_readptr, writeq2_readptr, readq1_writeptr, readq2_writeptr;
  reg wfull_r, rempty_r;

  wire writeinc, readinc, wfull_n, rempty_n;
  wire[3:0]writeptr_bin_n, readptr_bin_n, writeptr_n, readptr_n;

  assign writeinc = wvalid && !wfull_r;
  assign readinc = rd_en && !rempty_r;

  assign writeptr_bin_n = writeptr_bin + {3'b000, writeinc};
  assign readptr_bin_n = readptr_bin + {3'b000, readinc};

  assign writeptr_n = (writeptr_bin_n >> 1) ^ writeptr_bin_n;
  assign readptr_n = (readptr_bin_n >> 1) ^ readptr_bin_n;

  assign wfull_n = (writeptr_n == {~writeq2_readptr[3:2], writeq2_readptr[1:0]});
  assign rempty_n = (readptr_n == readq2_writeptr);

  assign wfull = wfull_r;
  assign rempty = rempty_r;

  always @(posedge wclk or negedge rstn) 
    begin
      if(!rstn) 
        begin
          writeptr_bin <= 4'd0;
          writeptr <= 4'd0;
          wfull_r <= 1'b0;
        end 
      else 
        begin
          if(writeinc) 
            mem[writeptr_bin[2:0]] <= wdata;
          writeptr_bin <= writeptr_bin_n;
          writeptr <= writeptr_n;
          wfull_r <= wfull_n;
        end
    end

  always @(posedge rclk or negedge rstn) 
    begin
      if(!rstn) 
        begin
          readptr_bin <= 4'd0;
          readptr <= 4'd0;
          rempty_r <= 1'b1;
          rdata <= 16'd0;
          rvalid <= 1'b0;
        end 
      else 
        begin
          rvalid <= readinc;
          if(readinc) 
            rdata <= mem[readptr_bin[2:0]];
          readptr_bin <= readptr_bin_n;
          readptr <= readptr_n;
          rempty_r <= rempty_n;
        end
    end

  always @(posedge wclk or negedge rstn)
    begin
      if(!rstn) 
        begin
          writeq1_readptr <= 4'd0;
          writeq2_readptr <= 4'd0;
        end 
      else 
        begin
          writeq1_readptr <= readptr;
          writeq2_readptr <= writeq1_readptr;
        end
    end

  always @(posedge rclk or negedge rstn) 
    begin
      if(!rstn) 
        begin
          readq1_writeptr <= 4'd0;
          readq2_writeptr <= 4'd0;
        end 
      else 
        begin
          readq1_writeptr <= writeptr;
          readq2_writeptr <= readq1_writeptr;
        end
    end

endmodule



