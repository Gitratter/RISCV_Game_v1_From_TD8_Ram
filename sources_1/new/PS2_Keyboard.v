module PS2_Keyboard(
    input wire clk,
    input wire reset,
    input wire ps2_clk,
    input wire ps2_data,
    output reg [7:0] key_code,
    output reg key_valid
    );

    reg [2:0] ps2_clk_sync;
    wire ps2_clk_fall;

    reg [3:0] bit_count;
    reg [10:0] shift_reg;
    reg break_code;

    assign ps2_clk_fall = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clk or posedge reset) begin
        if (reset)
            ps2_clk_sync <= 3'b111;
        else
            ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_count  <= 4'd0;
            shift_reg  <= 11'd0;
            key_code   <= 8'h00;
            key_valid  <= 1'b0;
            break_code <= 1'b0;
        end else begin
            key_valid <= 1'b0;

            if (ps2_clk_fall) begin
                shift_reg <= {ps2_data, shift_reg[10:1]};

                if (bit_count == 4'd10) begin
                    bit_count <= 4'd0;

                    // start=0, stop=1, odd parity を確認
                    if ((shift_reg[1] == 1'b0) &&
                        (ps2_data == 1'b1) &&
                        (^shift_reg[10:2] == 1'b1)) begin

                        if (shift_reg[9:2] == 8'hF0) begin
                            break_code <= 1'b1;
                        end else if (break_code) begin
                            break_code <= 1'b0;
                        end else begin
                            key_code  <= shift_reg[9:2];
                            key_valid <= 1'b1;
                        end
                    end
                end else begin
                    bit_count <= bit_count + 4'd1;
                end
            end
        end
    end
endmodule
