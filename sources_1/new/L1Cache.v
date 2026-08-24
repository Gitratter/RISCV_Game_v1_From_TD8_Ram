module L1Cache (
    input wire clk,
    input wire reset,
    
    input wire [31:0] cpu_addr,
    output reg [31:0] cpu_instr,
    output reg stall_cpu,
    
    output reg [31:0] mem_addr,
    input wire [31:0] mem_instr,
    input wire mem_ready
);

    parameter ENTRIES = 256;
    
    reg [31:0] data_array [0:ENTRIES-1];
    reg [21:0] tag_array  [0:ENTRIES-1];
    reg        valid_array [0:ENTRIES-1];
    
    localparam IDLESTATE    = 2'b00;
    localparam STATE_FETCH  = 2'b01;
    localparam STATE_UPDATE = 2'b10;
    
    reg [1:0] state;
    integer i;

    wire [7:0]  index = cpu_addr[9:2];
    wire [21:0] tag   = cpu_addr[31:10];
    
    wire hit = valid_array[index] && (tag_array[index] == tag);

    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            state <= IDLESTATE;
            stall_cpu <= 0;
            for (i = 0; i < ENTRIES; i = i + 1) begin
                valid_array[i] <= 0;
            end
        end 
        else begin
            case (state)
                IDLESTATE: begin
                    if (hit) begin
                        cpu_instr <= data_array[index]; 
                        stall_cpu <= 0;
                        state     <= IDLESTATE;
                    end else begin
                        stall_cpu <= 1;            
                        state     <= STATE_FETCH;
                    end
                end

                STATE_FETCH: begin
                    mem_addr <= cpu_addr;          
                    if (mem_ready) begin
                        state <= STATE_UPDATE;
                    end else begin
                        state <= STATE_FETCH;      
                    end
                end

                STATE_UPDATE: begin
                    data_array[index]  <= mem_instr; 
                    tag_array[index]   <= tag;
                    valid_array[index] <= 1'b1;
                    state <= IDLESTATE;            
                end
            endcase
        end
    end
endmodule