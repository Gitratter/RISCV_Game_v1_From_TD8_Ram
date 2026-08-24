module Tetris_Controller(
    input wire clk,
    input wire reset,
    input wire [7:0] key_code,
    input wire key_valid,

    output reg [3:0] falling_x,
    output reg [4:0] falling_y,
    output reg [2:0] piece_type,
    output reg [2:0] piece_color,
    output reg [1:0] piece_rotation
    );

    localparam [26:0] DROP_COUNT = 27'd50_000_000;

    reg [26:0] drop_counter;
    reg [7:0] lfsr;

    wire soft_drop = key_valid && (key_code == 8'h1B); // S
    wire [1:0] cw_rotation = piece_rotation + 2'd1;
    wire [1:0] ccw_rotation = piece_rotation - 2'd1;

    wire [11:0] current_extents =
        piece_extents(piece_type, piece_rotation);
    wire [11:0] cw_extents =
        piece_extents(piece_type, cw_rotation);
    wire [11:0] ccw_extents =
        piece_extents(piece_type, ccw_rotation);

    wire [2:0] left_extent = current_extents[11:9];
    wire [2:0] right_extent = current_extents[8:6];
    wire [2:0] down_extent = current_extents[2:0];

    function [11:0] piece_extents;
        input [2:0] shape;
        input [1:0] rotation;

        reg [2:0] left_e;
        reg [2:0] right_e;
        reg [2:0] up_e;
        reg [2:0] down_e;
        reg [2:0] temporary;
        integer i;
        begin
            case (shape)
                3'd0: begin // O
                    left_e  = 3'd1;
                    right_e = 3'd0;
                    up_e    = 3'd0;
                    down_e  = 3'd1;
                end

                3'd1: begin // I
                    left_e  = 3'd2;
                    right_e = 3'd1;
                    up_e    = 3'd0;
                    down_e  = 3'd0;
                end

                3'd5,
                3'd6: begin // S, Z
                    left_e  = 3'd1;
                    right_e = 3'd1;
                    up_e    = 3'd1;
                    down_e  = 3'd0;
                end

                default: begin // T, L, J
                    left_e  = 3'd1;
                    right_e = 3'd1;
                    up_e    = 3'd0;
                    down_e  = 3'd1;
                end
            endcase

            if (shape != 3'd0) begin
                for (i = 0; i < 3; i = i + 1) begin
                    if (i < rotation) begin
                        temporary = left_e;
                        left_e = down_e;
                        down_e = right_e;
                        right_e = up_e;
                        up_e = temporary;
                    end
                end
            end

            piece_extents = {left_e, right_e, up_e, down_e};
        end
    endfunction

    function rotation_fits;
        input [11:0] extents;
        reg [2:0] test_left;
        reg [2:0] test_right;
        reg [2:0] test_up;
        reg [2:0] test_down;
        begin
            test_left  = extents[11:9];
            test_right = extents[8:6];
            test_up    = extents[5:3];
            test_down  = extents[2:0];

            rotation_fits =
                (falling_x >= test_left) &&
                (falling_x + test_right <= 4'd9) &&
                (falling_y >= test_up) &&
                (falling_y + test_down <= 5'd19);
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            falling_x      <= 4'd4;
            falling_y      <= 5'd2;
            piece_type     <= 3'd0;
            piece_color    <= 3'b100;
            piece_rotation <= 2'd0;
            drop_counter   <= 27'd0;
            lfsr           <= 8'hA5;
        end else begin
            if ((drop_counter == DROP_COUNT - 1) || soft_drop) begin
                drop_counter <= 27'd0;

                if (falling_y + down_extent < 5'd19) begin
                    falling_y <= falling_y + 5'd1;
                end else begin
                    falling_x      <= 4'd4;
                    falling_y      <= 5'd2;
                    piece_rotation <= 2'd0;

                    if (lfsr[2:0] == 3'd7)
                        piece_type <= 3'd0;
                    else
                        piece_type <= lfsr[2:0];

                    if (lfsr[5:3] == 3'd0)
                        piece_color <= 3'b001;
                    else
                        piece_color <= lfsr[5:3];

                    lfsr <= {lfsr[6:0],
                             lfsr[7] ^ lfsr[5] ^
                             lfsr[4] ^ lfsr[3]};
                end
            end else begin
                drop_counter <= drop_counter + 27'd1;

                if (key_valid) begin
                    case (key_code)
                        8'h1C: begin // A: left
                            if (falling_x > left_extent)
                                falling_x <= falling_x - 4'd1;
                        end

                        8'h23: begin // D: right
                            if (falling_x + right_extent < 4'd9)
                                falling_x <= falling_x + 4'd1;
                        end

                        8'h15: begin // Q: clockwise
                            if (rotation_fits(cw_extents))
                                piece_rotation <= cw_rotation;
                        end

                        8'h24: begin // E: counter-clockwise
                            if (rotation_fits(ccw_extents))
                                piece_rotation <= ccw_rotation;
                        end
                    endcase
                end
            end
        end
    end
endmodule