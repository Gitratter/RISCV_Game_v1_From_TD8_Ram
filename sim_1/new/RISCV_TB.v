module RISCV_TB;

    // Inputs to the CPU
    reg clk;
    reg reset;

    // Outputs from the CPU (for debugging)
    // FIXED: Changed to 16 bits to perfectly match RISCV_Top
    wire [15:0] DataAddr; 

    // Instantiate the Unit Under Test (UUT)
    RISCV_Top uut (
        .clk(clk),
        .reset(reset),
        // FIXED: Removed WriteData
        .DataAddr(DataAddr)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;

        // Wait 20 ns for global reset to finish
        #20;
        reset = 0; // Release reset, CPU starts running!

        // Let it run for 2000ns (gives the divided clock time to tick)
        #2000;
        
        // Stop simulation
        $finish;
    end
      
endmodule
