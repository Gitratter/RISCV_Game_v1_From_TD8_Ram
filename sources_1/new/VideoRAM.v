module VideoRAM(
    input wire clk,

    input wire [12:0] read_addr,
    output wire [7:0] read_char,

    input wire write_enable,
    input wire [12:0] write_addr,
    input wire [7:0] write_char
    );

    reg [7:0] mem [0:4799];
    integer i;

    initial begin
        for (i = 0; i < 4800; i = i + 1) begin
            mem[i] = 8'h20; // space
        end
    end

    assign read_char = mem[read_addr];

    always @(posedge clk) begin
        if (write_enable) begin
            mem[write_addr] <= write_char;
        end
    end
endmodule
