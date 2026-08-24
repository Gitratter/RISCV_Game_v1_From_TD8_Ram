module InstructionMemory(
    input [31:0] Address,
    output [31:0] Instruction
    );

    reg [31:0] memory [63:0];

    initial begin
        // x1 = 0x00001000
        memory[0]  = 32'h40000093; // addi x1, x0, 1024
        memory[1]  = 32'h001080B3; // add  x1, x1, x1
        memory[2]  = 32'h001080B3; // add  x1, x1, x1

        // VRAM[0] = 'H'
        memory[3]  = 32'h04800113; // addi x2, x0, 72
        memory[4]  = 32'h0020A023; // sw x2, 0(x1)

        // VRAM[1] = 'E'
        memory[5]  = 32'h04500113; // addi x2, x0, 69
        memory[6]  = 32'h0020A223; // sw x2, 4(x1)

        // VRAM[2] = 'L'
        memory[7]  = 32'h04C00113; // addi x2, x0, 76
        memory[8]  = 32'h0020A423; // sw x2, 8(x1)

        // VRAM[3] = 'L'
        memory[9]  = 32'h04C00113; // addi x2, x0, 76
        memory[10] = 32'h0020A623; // sw x2, 12(x1)

        // VRAM[4] = 'O'
        memory[11] = 32'h04F00113; // addi x2, x0, 79
        memory[12] = 32'h0020A823; // sw x2, 16(x1)

        // loop
        memory[13] = 32'h00000063; // beq x0, x0, 0
    end

    assign Instruction = memory[Address[31:2]];

endmodule