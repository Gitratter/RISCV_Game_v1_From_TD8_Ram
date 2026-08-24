module ImmGen(
    input [31:0] Instruction, // The full instruction
    output reg [31:0] ImmExt  // The 32-bit extended immediate
    );

    wire [6:0] opcode = Instruction[6:0];

    always @(*) begin
        case(opcode)
            // I-Type (ADDI, LW) - 12 bits
            // Immediate is in Instruction[31:20]
            7'b0010011, 7'b0000011: 
                ImmExt = {{20{Instruction[31]}}, Instruction[31:20]};

            // S-Type (SW) - 12 bits split into two parts
            // Immediate is split: [31:25] and [11:7]
            7'b0100011: 
                ImmExt = {{20{Instruction[31]}}, Instruction[31:25], Instruction[11:7]};

            // B-Type (BEQ) - 13 bits, highly scrambled!
            // Used for branches. The bit at index 0 is always 0.
            7'b1100011: 
                ImmExt = {{20{Instruction[31]}}, Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0};

            // J-Type (JAL) - 21 bits (Optional, for jumps)
            7'b1101111: 
                ImmExt = {{12{Instruction[31]}}, Instruction[19:12], Instruction[20], Instruction[30:21], 1'b0};

            default: 
                ImmExt = 32'b0;
        endcase
    end
endmodule