module ControlUnit(
    input [6:0] Opcode,       // The 7-bit opcode from Instruction[6:0]
    output reg Branch,        // Tell the PC logic we might branch
    output reg MemRead,       // Tell Data Memory to read
    output reg MemToReg,      // 1=Write from Memory, 0=Write from ALU
    output reg [1:0] ALUOp,   // 2-bit code to tell ALU Decoder what to do
    output reg MemWrite,      // Tell Data Memory to write
    output reg ALUSrc,        // 0=Read Register B, 1=Read Immediate
    output reg RegWrite       // Tell Register File to write
    );

    always @(*) begin
        // Initialize everything to 0 to prevent latches
        Branch = 0; MemRead = 0; MemToReg = 0; MemWrite = 0; ALUSrc = 0; RegWrite = 0; ALUOp = 2'b00;

        case(Opcode)
            // R-Type (ADD, SUB, AND, OR, etc.)
            7'b0110011: begin
                RegWrite = 1;
                ALUOp = 2'b10; // "Look at funct3/7"
            end

            // I-Type (ADDI, ANDI, etc.)
            7'b0010011: begin
                ALUSrc = 1;    // Use Immediate, not Register B
                RegWrite = 1;
                ALUOp = 2'b10; // Treat like R-type arithmetic
            end

            // Load Word (LW)
            7'b0000011: begin
                ALUSrc = 1;
                MemToReg = 1;  // Data comes from Memory, not ALU
                RegWrite = 1;
                MemRead = 1;
                ALUOp = 2'b00; // Force ADD (Address calculation)
            end

            // Store Word (SW)
            7'b0100011: begin
                ALUSrc = 1;
                MemWrite = 1;
                ALUOp = 2'b00; // Force ADD (Address calculation)
            end

            // Branch Equal (BEQ)
            7'b1100011: begin
                Branch = 1;
                ALUOp = 2'b01; // Force SUB (Comparison)
            end
        endcase
    end
endmodule