module ALUDecoder(
    input [1:0] ALUOp,          // From Control Unit
    input [2:0] Funct3,         // Instruction[14:12]
    input Funct7,               // Instruction[30] (Only need 1 bit to distinguish ADD/SUB)
    input [6:0] Opcode,         // Helpful to distinguish I-Type vs R-Type
    output reg [3:0] ALUControl // Signal to ALU
    );

    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0010; // LW/SW -> Force ADD
            2'b01: ALUControl = 4'b0110; // BEQ   -> Force SUB
            2'b10: begin                 // R-Type or I-Type
                case(Funct3)
                    3'b000: begin // ADD or SUB
                         // If it's R-Type (0110011) and Funct7 is 1, it's SUB. Otherwise ADD.
                         if (Opcode == 7'b0110011 && Funct7 == 1'b1) 
                             ALUControl = 4'b0110; // SUB
                         else 
                             ALUControl = 4'b0010; // ADD
                    end
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b111: ALUControl = 4'b0000; // AND
                    3'b010: ALUControl = 4'b0111; // SLT
                    default: ALUControl = 4'b0000; // Default to 0
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule
