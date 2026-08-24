module RegisterFile(
    input clk,
    input en,                   
    input RegWrite,
    input [4:0] ReadReg1,
    input [4:0] ReadReg2,
    input [4:0] WriteReg,
    input [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2,
    
    input [4:0] DebugReg,
    output [31:0] DebugData
    );
  
    reg [31:0] registers [31:0];
    integer i;


    assign DebugData =
        (DebugReg == 0) ? 32'b0 :
        registers[DebugReg];


    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    assign ReadData1 = (ReadReg1 == 0) ? 32'b0 : registers[ReadReg1];
    assign ReadData2 = (ReadReg2 == 0) ? 32'b0 : registers[ReadReg2];

    always @(posedge clk) begin
        // Only write on the clock edge IF the enable tick is high
        if (en && RegWrite && WriteReg != 0) begin
            registers[WriteReg] <= WriteData;
        end
    end
endmodule