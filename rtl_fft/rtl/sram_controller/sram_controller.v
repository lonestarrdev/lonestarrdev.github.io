module sram_controller # (
    parameter AW = 13
) (
    input clk,
    input rstn,
    input [7:0] counter_out,
    output reg sram_cen,
    output reg sram_gwen,
    output reg [AW-1:0] sram_addr
);

    always @(posedge clk or negedge rstn) begin
        
        if (!rstn) begin
            sram_cen <= 1'b1;
            sram_gwen <= 1'b1;
            sram_addr <= 0;
        end else begin
            if (counter_out == 8'd128) begin
                // When counter_out is 128, enable the write mode of the sram
                // this should write the value 127 into the sram address 6
                sram_cen <= 1'b0;
                sram_gwen <= 1'b0;
                sram_addr <= 6;
            end else if (counter_out == 8'd1) begin
                // When counter_out is 1, enable the read mode of the sram
                // this should read the value 127 from the sram address 6
                sram_cen <= 1'b1;
                sram_gwen <= 1'b0;
                sram_addr <= 6;
            end else begin
                sram_cen <= 1'b1;
                sram_gwen <= 1'b1;
                sram_addr <= 0;
            end
        end
    
    end

endmodule
