module ALU(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUControl,
    output reg [31:0] Result,
    output Zero
    );

    assign Zero = (Result == 0);

    always @(*) begin
        case (ALUControl)
            4'b0000: Result = A & B;
            4'b0001: Result = A | B;
            4'b0010: Result = A + B;
            4'b0110: Result = A - B;
            4'b0111: Result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; 
            4'b1001: Result = (A < B) ? 32'b1 : 32'b0;                   
            4'b1100: Result = ~(A | B);
            4'b0011: Result = A ^ B;
            4'b0100: Result = A << B[4:0];                               
            4'b0101: Result = A >> B[4:0];                               
            4'b1000: Result = $signed(A) >>> B[4:0];                     
            default: Result = 32'b0;
        endcase
    end
endmodule