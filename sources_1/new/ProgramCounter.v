module ProgramCounter(
    input wire clk,                  
    input wire reset,
    input wire en,
    input wire stall,                   
    input [31:0] NextPC,
    output reg [31:0] PC
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 32'b0; 
        end
        else if (stall) begin          
            PC <= PC;
        end
        else if (en) begin
            PC <= NextPC;
        end
    end
endmodule
