
module alu #(parameter inwidth = 16, parameter coeffw = 16, parameter prodw = 32, parameter aluw = 40)( input clk, input rstn, input signed [inwidth-1:0] sample, input signed [coeffw-1:0] coeff,
input clear, input enablealu, output reg signed [aluw-1:0] multout,output signed [prodw-1:0] outall);

    wire signed [prodw-1:0] mult_res;
    assign mult_res = $signed(sample) * $signed(coeff);

    wire signed [aluw-1:0] mult_ext;
	wire x;
    assign x = mult_res[prodw-1];
    assign mult_ext = {{(aluw-prodw){x}}, mult_res};

    always @(posedge clk or negedge rstn) 
        begin
            if (!rstn)
                multout <= {aluw{1'b0}};
            else if (clear)
                multout <= {aluw{1'b0}};
            else if (enablealu)
                multout <= multout + mult_ext;
        end

    assign outall = mult_res;

endmodule

