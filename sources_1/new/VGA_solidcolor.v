module VGA_Graphics(
    input wire clk,
    input wire reset,
    input wire [31:0] debug_value,
    output wire [12:0] vram_addr,
    input wire [7:0] vram_char,
    input wire [7:0] key_code,
    input wire key_valid,
    input wire [3:0] falling_x,
    input wire [4:0] falling_y,
    input wire [2:0] piece_type,
    input wire [2:0] piece_color,
    input wire [1:0] piece_rotation,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output wire Hsync,
    output wire Vsync
    );

    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_TOTAL   = 525;

    reg [1:0] clk_div;
    reg [9:0] x;
    reg [9:0] y;

    wire pixel_tick = (clk_div == 2'b11);
    wire active_video = (x < H_VISIBLE) && (y < V_VISIBLE);

    assign Hsync = ~((x >= H_VISIBLE + H_FRONT) &&
                     (x <  H_VISIBLE + H_FRONT + H_SYNC));

    assign Vsync = ~((y >= V_VISIBLE + V_FRONT) &&
                     (y <  V_VISIBLE + V_FRONT + V_SYNC));

    always @(posedge clk or posedge reset) begin
        if (reset)
            clk_div <= 2'b00;
        else
            clk_div <= clk_div + 2'b01;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pixel_tick) begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
                if (y == V_TOTAL - 1)
                    y <= 10'd0;
                else
                    y <= y + 10'd1;
            end else begin
                x <= x + 10'd1;
            end
        end
    end

    wire [6:0] cell_x = x[9:3];
    wire [5:0] cell_y = y[8:3];
    wire [2:0] font_x = x[2:0];
    wire [2:0] font_y = y[2:0];

    assign vram_addr = (cell_y * 80) + cell_x;
    
    
    reg [7:0] last_key;

    always @(posedge clk or posedge reset) begin
        if (reset)
            last_key <= 8'h00;
        else if (key_valid)
            last_key <= key_code;
    end

    wire [7:0] display_char = (cell_y == 1 && cell_x == 0) ? scan_to_ascii(last_key) : vram_char;
    wire text_pixel = font_pixel(display_char, font_x, font_y);
    localparam BOARD_LEFT = 220;
    localparam BOARD_TOP  = 80;
    localparam CELL_SIZE  = 16;

    wire board_area =
        active_video &&
        (x >= BOARD_LEFT) && (x < BOARD_LEFT + 160) &&
        (y >= BOARD_TOP)  && (y < BOARD_TOP + 320);

    wire [9:0] board_rel_x = x - BOARD_LEFT;
    wire [9:0] board_rel_y = y - BOARD_TOP;

    wire [3:0] board_cell_x = board_rel_x >> 4;
    wire [4:0] board_cell_y = board_rel_y >> 4;

    wire board_grid =
        board_area &&
        ((board_rel_x[3:0] == 4'd0) ||
         (board_rel_y[3:0] == 4'd0));


    wire falling_block =
        board_area &&
        tetromino_cell(
            piece_type,
            piece_rotation,
            board_cell_x,
            board_cell_y,
            falling_x,
            falling_y
        );

// Replace the complete old tetromino_cell function with this:
    function tetromino_cell;
        input [2:0] shape;
        input [1:0] rotation;
        input [3:0] cell_x;
        input [4:0] cell_y;
        input [3:0] pivot_x;
        input [4:0] pivot_y;

        integer dx;
        integer dy;
        integer base_x;
        integer base_y;
        integer temporary;
        integer i;
        begin
            dx = cell_x;
            dx = dx - pivot_x;
            dy = cell_y;
            dy = dy - pivot_y;

            base_x = dx;
            base_y = dy;

        // Convert the displayed coordinate back to rotation 0.
            for (i = 0; i < 3; i = i + 1) begin
                if ((shape != 3'd0) && (i < rotation)) begin
                    temporary = base_x;
                    base_x = base_y;
                    base_y = -temporary;
                end
            end

            case (shape)
                3'd0: // O
                    tetromino_cell =
                        ((dx == -1) || (dx == 0)) &&
                        ((dy == 0) || (dy == 1));

                3'd1: // I
                    tetromino_cell =
                        (base_y == 0) &&
                        (base_x >= -2) && (base_x <= 1);

                3'd2: // T
                    tetromino_cell =
                        ((base_y == 0) &&
                        (base_x >= -1) && (base_x <= 1)) ||
                        ((base_x == 0) && (base_y == 1));

                3'd3: // L
                    tetromino_cell =
                        ((base_y == 0) &&
                        (base_x >= -1) && (base_x <= 1)) ||
                        ((base_x == -1) && (base_y == 1));

                3'd4: // J
                    tetromino_cell =
                        ((base_y == 0) &&
                        (base_x >= -1) && (base_x <= 1)) ||
                        ((base_x == 1) && (base_y == 1));

                3'd5: // S
                    tetromino_cell =
                        ((base_y == -1) &&
                        ((base_x == 0) || (base_x == 1))) ||
                        ((base_y == 0) &&
                        ((base_x == -1) || (base_x == 0)));

                3'd6: // Z
                    tetromino_cell =
                        ((base_y == -1) &&
                        ((base_x == -1) || (base_x == 0))) ||
                        ((base_y == 0) &&
                        ((base_x == 0) || (base_x == 1)));

                default:
                    tetromino_cell = 1'b0;
            endcase
        end
    endfunction


    wire [11:0] falling_rgb = piece_rgb(piece_color);
    
    
 
    
    function [11:0] piece_rgb;
        input [2:0] color;
        begin
            case (color)
                3'b001: piece_rgb = 12'h08F; // 青
                3'b010: piece_rgb = 12'h0D4; // 緑
                3'b011: piece_rgb = 12'h0DD; // 水色
                3'b100: piece_rgb = 12'hF22; // 赤
                3'b101: piece_rgb = 12'hD0D; // 紫
                3'b110: piece_rgb = 12'hFD0; // 黄
                3'b111: piece_rgb = 12'hF70; // 橙
                default: piece_rgb = 12'hFFF;
            endcase
        end
    endfunction
    
    

    always @(*) begin
        if (!active_video) begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h0;

        end else if (falling_block) begin
            vgaRed   = falling_rgb[11:8];
            vgaGreen = falling_rgb[7:4];
            vgaBlue  = falling_rgb[3:0];

        end else if (board_grid) begin
            // テトリス盤面のマス目
            vgaRed   = 4'h3;
            vgaGreen = 4'h3;
            vgaBlue  = 4'h3;

        end else if (text_pixel) begin
            // VRAM文字表示
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;

        end else begin
            // 背景色
            vgaRed   = 4'h0;
            vgaGreen = 4'h2;
            vgaBlue  = 4'h5;
        end
    end
    
    
    function [7:0] scan_to_ascii;
        input [7:0] scan;
        begin
            case (scan)
                8'h1C: scan_to_ascii = 8'h41; // A
                8'h32: scan_to_ascii = 8'h42; // B
                8'h21: scan_to_ascii = 8'h43; // C
                8'h23: scan_to_ascii = 8'h44; // D
                8'h24: scan_to_ascii = 8'h45; // E
                8'h2B: scan_to_ascii = 8'h46; // F
                8'h34: scan_to_ascii = 8'h47; // G
                8'h33: scan_to_ascii = 8'h48; // H
                8'h43: scan_to_ascii = 8'h49; // I
                8'h3B: scan_to_ascii = 8'h4A; // J
                8'h42: scan_to_ascii = 8'h4B; // K
                8'h4B: scan_to_ascii = 8'h4C; // L
                8'h3A: scan_to_ascii = 8'h4D; // M
                8'h31: scan_to_ascii = 8'h4E; // N
                8'h44: scan_to_ascii = 8'h4F; // O
                8'h4D: scan_to_ascii = 8'h50; // P
                8'h15: scan_to_ascii = 8'h51; // Q
                8'h2D: scan_to_ascii = 8'h52; // R
                8'h1B: scan_to_ascii = 8'h53; // S
                8'h2C: scan_to_ascii = 8'h54; // T
                8'h3C: scan_to_ascii = 8'h55; // U
                8'h2A: scan_to_ascii = 8'h56; // V
                8'h1D: scan_to_ascii = 8'h57; // W
                8'h22: scan_to_ascii = 8'h58; // X
                8'h35: scan_to_ascii = 8'h59; // Y
                8'h1A: scan_to_ascii = 8'h5A; // Z
                default: scan_to_ascii = 8'h20; // space
            endcase
        end
    endfunction
    
    
    
    function font_pixel;
        input [7:0] ch;
        input [2:0] fx;
        input [2:0] fy;
        reg [7:0] row;
        begin
            row = 8'b00000000;

            case (ch)
                8'h41: begin // A
                    case (fy)
                        0: row = 8'b00111100;
                        1: row = 8'b01000010;
                        2: row = 8'b10000001;
                        3: row = 8'b11111111;
                        4: row = 8'b10000001;
                        5: row = 8'b10000001;
                        6: row = 8'b10000001;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h42: begin // B
                    case (fy)
                        0: row = 8'b11111100;
                        1: row = 8'b10000010;
                        2: row = 8'b10000010;
                        3: row = 8'b11111100;
                        4: row = 8'b10000010;
                        5: row = 8'b10000010;
                        6: row = 8'b11111100;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h43: begin // C
                    case (fy)
                        0: row = 8'b00111110;
                        1: row = 8'b01000000;
                        2: row = 8'b10000000;
                        3: row = 8'b10000000;
                        4: row = 8'b10000000;
                        5: row = 8'b01000000;
                        6: row = 8'b00111110;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h44: begin // D
                    case (fy)
                        0: row = 8'b11111100;
                        1: row = 8'b10000010;
                        2: row = 8'b10000001;
                        3: row = 8'b10000001;
                        4: row = 8'b10000001;
                        5: row = 8'b10000010;
                        6: row = 8'b11111100;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h45: begin // E
                    case (fy)
                        0: row = 8'b11111111;
                        1: row = 8'b10000000;
                        2: row = 8'b10000000;
                        3: row = 8'b11111100;
                        4: row = 8'b10000000;
                        5: row = 8'b10000000;
                        6: row = 8'b11111111;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h48: begin // H
                    case (fy)
                        0: row = 8'b10000001;
                        1: row = 8'b10000001;
                        2: row = 8'b10000001;
                        3: row = 8'b11111111;
                        4: row = 8'b10000001;
                        5: row = 8'b10000001;
                        6: row = 8'b10000001;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h4C: begin // L
                    case (fy)
                        0: row = 8'b10000000;
                        1: row = 8'b10000000;
                        2: row = 8'b10000000;
                        3: row = 8'b10000000;
                        4: row = 8'b10000000;
                        5: row = 8'b10000000;
                        6: row = 8'b11111111;
                        7: row = 8'b00000000;
                    endcase
                end

                8'h4F: begin // O
                    case (fy)
                        0: row = 8'b01111110;
                        1: row = 8'b10000001;
                        2: row = 8'b10000001;
                        3: row = 8'b10000001;
                        4: row = 8'b10000001;
                        5: row = 8'b10000001;
                        6: row = 8'b01111110;
                        7: row = 8'b00000000;
                    endcase
                end

                default: row = 8'b00000000;
            endcase

            font_pixel = row[7 - fx];
        end
    endfunction
endmodule
