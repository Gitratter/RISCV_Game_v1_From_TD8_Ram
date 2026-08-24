module RISCV_Top(
    input clk,              
    input reset,            
    //output [15:0] DataAddr,
    //input wire sw_stall,
    
    input [4:0] sw,
    //output [31:0] debug_reg,
    
    input ps2_clk,
    input ps2_data,
    
    output [15:0] led,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync
    );

    wire [31:0] mem_instr_wire; 
    wire [31:0] debug_reg;
    
    
    wire enable_tick;       
    wire [31:0] PC_In, PC_Out;
    wire [31:0] Instr;
    wire [31:0] ReadData1, ReadData2;
    wire [31:0] ImmExt;
    wire [31:0] SrcB;
    wire [31:0] ALUResult;
    wire [31:0] ReadData;
    wire [31:0] Result;
    wire Zero;
    wire [31:0] cache_mem_addr;
    wire cache_stall;
    
    wire [12:0] vram_addr;
    wire [7:0] vram_char;
    
    wire [7:0] key_code;
    wire key_valid;
    
    wire [3:0] falling_x;
    wire [4:0] falling_y;
    
    wire [2:0] piece_type;
    wire [2:0] piece_color;
    wire [1:0] piece_rotation;

    wire final_stall = cache_stall;
    wire MemWrite, MemRead, ALUSrc, RegWrite, MemToReg, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUControl;
    
    
    
    localparam VRAM_BASE = 32'h00001000;
    wire is_vram_addr;
    wire [31:0] vram_offset;
    wire [12:0] cpu_vram_addr;
    wire vram_write_enable;

    assign is_vram_addr = (ALUResult >= VRAM_BASE) &&
                          (ALUResult <  VRAM_BASE + 32'd19200);

    assign vram_offset = ALUResult - VRAM_BASE;
    assign cpu_vram_addr = vram_offset[14:2];

    assign vram_write_enable =
        MemWrite & enable_tick & ~final_stall & is_vram_addr;
    
 
    
    ClockDivider clk_div (
        .clk(clk),
        .reset(reset),
        .enable_tick(enable_tick)
    );

    wire [31:0] PCPlus4 = PC_Out + 4;
    wire [31:0] PCTarget = PC_Out + ImmExt;
    wire PCSrc = Branch & Zero;
    assign PC_In = (PCSrc) ? PCTarget : PCPlus4;

    ProgramCounter pc_module (
        .clk(clk),
        .reset(reset),
        .en(enable_tick),
        .stall(final_stall),   
        .NextPC(PC_In),
        .PC(PC_Out)
    );

    L1Cache icache (
        .clk(clk),
        .reset(reset),
        
        // CPU Side
        .cpu_addr(PC_Out),          
        .cpu_instr(Instr),          
        .stall_cpu(cache_stall),    
        
        // Memory Side
        .mem_addr(cache_mem_addr),  
        .mem_instr(mem_instr_wire), 
        .mem_ready(1'b1)            // Hardcoded to 1 (Instant memory for now)
    );

    InstructionMemory imem (
        .Address(cache_mem_addr),
        .Instruction(mem_instr_wire)
    );

    ControlUnit control (
        .Opcode(Instr[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemToReg(MemToReg),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ALUOp(ALUOp)
    );
    
    wire RegWrite_gated = RegWrite & ~final_stall;
    
    RegisterFile reg_file (
        .clk(clk),          
        .en(enable_tick),   
        .RegWrite(RegWrite_gated),
        .ReadReg1(Instr[19:15]),
        .ReadReg2(Instr[24:20]),
        .WriteReg(Instr[11:7]),
        .WriteData(Result),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        
        .DebugReg(sw),
        .DebugData(debug_reg)
    );

    ImmGen imm_gen (
        .Instruction(Instr),
        .ImmExt(ImmExt)
    );

    assign SrcB = (ALUSrc) ? ImmExt : ReadData2;

    ALUDecoder alu_dec (
        .ALUOp(ALUOp),
        .Funct3(Instr[14:12]),
        .Funct7(Instr[30]),
        .Opcode(Instr[6:0]),
        .ALUControl(ALUControl)
    );

    ALU alu (
        .A(ReadData1),
        .B(SrcB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    DataMemory dmem (
        .clk(clk),       
        .MemWrite(MemWrite & enable_tick & ~final_stall & ~is_vram_addr), 
        .MemRead(MemRead),
        .Address(ALUResult),
        .WriteData(ReadData2),
        .ReadData(ReadData)
    );

    assign Result = (MemToReg) ? ReadData : ALUResult;
    
    //assign DataAddr = ALUResult[15:0];
    
    //assign led = debug_reg[15:0];
    reg [7:0] key_debug;
    always @(posedge clk or posedge reset) begin
        if (reset)
            key_debug <= 8'h00;
        else if (key_valid)
            key_debug <= key_code;
    end

    assign led = {8'h00, key_debug};
    
    /*
    VGA_SolidColor vga_solid_color (
        .clk(clk),
        .reset(reset),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue),
        .Hsync(Hsync),
        .Vsync(Vsync)
    );
    */
    
    VGA_Graphics vga_graphics (
        .clk(clk),
        .reset(reset),
        .debug_value(debug_reg),
        
        .vram_addr(vram_addr),
        .vram_char(vram_char),
        
        .key_code(key_code),
        .key_valid(key_valid),
        
        .falling_x(falling_x),
        .falling_y(falling_y),
        
        .piece_type(piece_type),
        .piece_color(piece_color),
        .piece_rotation(piece_rotation),
        
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue),
        .Hsync(Hsync),
        .Vsync(Vsync)
    );
    
    
    VideoRAM vram (
        .clk(clk),
        .read_addr(vram_addr),
        .read_char(vram_char),

        .write_enable(vram_write_enable),
        .write_addr(cpu_vram_addr),
        .write_char(ReadData2[7:0])
    );
    
    
    PS2_Keyboard keyboard (
        .clk(clk),
        .reset(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .key_code(key_code),
        .key_valid(key_valid)
    );
    
    
    Tetris_Controller tetris (
        .clk(clk),
        .reset(reset),
        .key_code(key_code),
        .key_valid(key_valid),
        .falling_x(falling_x),
        .falling_y(falling_y),
        
        .piece_type(piece_type),
        .piece_color(piece_color),
        .piece_rotation(piece_rotation)
    );
    
endmodule
