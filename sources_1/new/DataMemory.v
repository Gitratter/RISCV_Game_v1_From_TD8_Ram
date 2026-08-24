module DataMemory(
    input clk,
    input MemWrite,            
    input MemRead,             
    input [31:0] Address,      // Address from ALU
    input [31:0] WriteData,    // Data from Register File (ReadData2)
    output [31:0] ReadData     // Data going back to Register File
    );

    reg [31:0] RAM [63:0];

    assign ReadData = RAM[Address[31:2] & 6'b111111];

    // Write Logic (Synchronous)
    always @(posedge clk) begin
        if (MemWrite) begin
            RAM[Address[31:2] & 6'b111111] <= WriteData;
        end
    end
endmodule