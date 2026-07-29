`timescale 1ns/1ps

module fircore(input wire clk1,input wire clk2,input wire rstn,input wire signed [15:0] din,input wire valid_in,output wire wfull,input wire cload,input wire [5:0] caddr,input wire signed [15:0] cin,output reg signed [15:0] dout,output reg valid_out,output wire sgn,output wire rempty);

  reg [2:0] st;
  reg [5:0] wptr;
  reg [5:0] newest;
  reg [6:0] k;

  wire [15:0] rdata;
  wire rvalid;
  wire rd_en;
  assign rd_en = (st==3'd1); //same thing later

  fifo fifo_0(.wclk(clk1),.rclk(clk2),.rstn(rstn),.wdata(din),.wvalid(valid_in),//fifo start
.rd_en(rd_en),.wfull(wfull),.rempty(rempty),.rdata(rdata),.rvalid(rvalid));

  wire write_en;
  wire [5:0] write_addr;
  wire signed [15:0] write_data;
  wire signed [15:0] out_data;

  assign write_en=(st==3'd2) & rvalid;
  assign write_addr=wptr;
  assign write_data=rdata;
reg [5:0] read_addr;
always @(*) //wire assign for coeffs read addr output for mult
  begin
    read_addr = 6'd0;
    if(st==3'd3)
      begin
        read_addr = newest;
      end
    else if(st==3'd4 && k<7'd63)
      begin
        read_addr = newest - (k + 7'd1);
      end
  end


  regfile regfile_0(.clk(clk2),.rstn(rstn),.write_en(write_en),.write_addr(write_addr),//regfile start
.write_data(write_data),.read_addr(read_addr),.out_data(out_data));

  wire signed [15:0] coef_out;

reg [5:0] coef_read_addr;
always @(*) //wire assign for coeffs write addr output for mult
  begin
    coef_read_addr = 6'd0;
    if(st==3'd3)
      begin
        coef_read_addr = 6'd0;
      end
    else if(st==3'd4 && k<7'd63)
      begin
        coef_read_addr = k[5:0] + 6'd1;
      end
  end

  cmem cmem_0(.clk(clk2),.rstn(rstn),.cload(cload),.caddr(caddr),
.cin(cin),.coef_read_addr(coef_read_addr),.coef_out(coef_out));

  wire clear;
  wire enablealu;
  assign clear=(st==3'd3);
  assign enablealu=(st==3'd4);

  wire signed [39:0] multout;
  wire signed [31:0] outall;

  alu alu_0(.clk(clk2),.rstn(rstn),.sample(out_data),.coeff(coef_out),
.clear(clear),.enablealu(enablealu),.multout(multout),.outall(outall));

  function signed [15:0] overflow;
    input signed [39:0] x;
    begin
      if (x>$signed({1'b0,16'h7FFF})) 
	overflow=16'sh7FFF;
      else if (x<$signed({1'b1,16'h8000})) 
	overflow=16'sh8000;
      else overflow=x[15:0];
    end
  endfunction

  wire signed [39:0] acc_s;
  assign acc_s=(multout>>>21); //shif tfor oflow

  assign sgn=dout[15];

always @(posedge clk2 or negedge rstn)//all fsm
  begin
    if(!rstn)
      begin
        st <= 3'd0;
        wptr <= 6'd0;
        newest <= 6'd0;
        k <= 7'd0;
        dout <= 16'sd0;
        valid_out <= 1'b0;
      end
    else
      begin
        valid_out <= 1'b0;
        case(st)
          3'd0:
            begin
              if(!rempty)
                begin
                  st <= 3'd1;
                end
            end
          3'd1:
            begin
              st <= 3'd2;
            end
          3'd2:
            begin
              if(rvalid)
                begin
                  newest <= wptr;
                  wptr <= wptr + 6'd1;
                  k <= 7'd0;
                  st <= 3'd3;
                end
              else
                begin
                  st <= 3'd0;
                end
            end
          3'd3:
            begin
              k <= 7'd0;
              st <= 3'd4;
            end
          3'd4:
            begin
              if(k<7'd63)
                begin
                  k <= k + 7'd1;
                  st <= 3'd4;
                end
              else
                begin
                  st <= 3'd5;
                end
            end
          3'd5:
            begin
              dout <= acc_s[15:0];
              valid_out <= 1'b1;
              st <= 3'd0;
            end
          default:
            begin
              st <= 3'd0;
            end
        endcase
      end
  end


endmodule

