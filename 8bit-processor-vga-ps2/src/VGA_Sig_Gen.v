`timescale 1ns / 1ps

//==============================================================
// Module: VGA_Sig_Gen
// Description:
// Generates VGA timing signals and pixel output.
//
// This version includes:
// 1. 640x480 @ 60 Hz VGA timing
// 2. 160x120 logical framebuffer mapping
// 3. Permanent 3x3 yellow grid overlay
// 4. Permanent region letters overlay:
//    FL, F, FR
//    L,  I, R
//    BL, B, BR
//
// Works with:
//   - Frame_Buffer
//   - VGA_Interface
//==============================================================

module VGA_Sig_Gen(
    input              CLK,            // 25 MHz VGA clock
    input      [15:0]  CONFIG_COLOURS, // {BG, FG}
    output             DPR_CLK,
    output reg [14:0]  VGA_ADDR,
    input              VGA_DATA,
    output reg         VGA_HS,
    output reg         VGA_VS,
    output reg [7:0]   VGA_COLOUR
);

    //==========================================================
    // VGA Timing Parameters (640x480 @ 60Hz)
    //==========================================================
    parameter HTs    = 800;
    parameter HTpw   = 96;
    parameter HTDisp = 640;
    parameter Hbp    = 48;
    parameter Hfp    = 16;

    parameter VTs    = 521;
    parameter VTpw   = 2;
    parameter VTDisp = 480;
    parameter Vbp    = 29;
    parameter Vfp    = 10;

    assign DPR_CLK = CLK;

    //==========================================================
    // Counters
    //==========================================================
    reg [9:0] h_cnt = 10'd0;
    reg [9:0] v_cnt = 10'd0;

    //==========================================================
    // Colours
    //==========================================================
    wire [7:0] BG = CONFIG_COLOURS[15:8];
    wire [7:0] FG = CONFIG_COLOURS[7:0];

    // Overlay colours
    wire [7:0] GRID_COLOUR  = 8'hFC; // yellow
    wire [7:0] TEXT_COLOUR  = 8'hFF; // white

    //==========================================================
    // Display control
    //==========================================================
    wire display_on;
    wire hs_active;
    wire vs_active;

    wire [7:0] fb_x;
    wire [6:0] fb_y;

    reg display_on_d;

    assign display_on = (h_cnt < HTDisp) && (v_cnt < VTDisp);

    assign hs_active = (h_cnt >= (HTDisp + Hfp)) &&
                       (h_cnt <  (HTDisp + Hfp + HTpw));

    assign vs_active = (v_cnt >= (VTDisp + Vfp)) &&
                       (v_cnt <  (VTDisp + Vfp + VTpw));

    //==========================================================
    // 640x480 -> 160x120 logical mapping
    // divide by 4
    //==========================================================
    assign fb_x = h_cnt[9:2];
    assign fb_y = v_cnt[8:2];

    //==========================================================
    // Grid overlay (3x3)
    // logical screen: 160x120
    // vertical divisions near x = 53, 106
    // horizontal divisions near y = 40, 80
    // 3-pixel thick lines for visibility
    //==========================================================
    wire grid_on;
    assign grid_on =
        ((fb_x >= 8'd52)  && (fb_x <= 8'd54))  ||
        ((fb_x >= 8'd105) && (fb_x <= 8'd107)) ||
        ((fb_y >= 7'd39)  && (fb_y <= 7'd41))  ||
        ((fb_y >= 7'd79)  && (fb_y <= 7'd81));

    //==========================================================
    // Character drawing function (5x7 font)
    //==========================================================
    localparam [2:0] CHAR_NONE = 3'd0;
    localparam [2:0] CHAR_F    = 3'd1;
    localparam [2:0] CHAR_B    = 3'd2;
    localparam [2:0] CHAR_L    = 3'd3;
    localparam [2:0] CHAR_R    = 3'd4;
    localparam [2:0] CHAR_I    = 3'd5;

    function [0:0] char_pixel;
        input [2:0] ch;
        input [2:0] x;
        input [2:0] y;
        begin
            case (ch)
                // F
                CHAR_F: begin
                    case (y)
                        3'd0: char_pixel = (x <= 3'd4);
                        3'd1: char_pixel = (x == 3'd0);
                        3'd2: char_pixel = (x == 3'd0);
                        3'd3: char_pixel = (x <= 3'd3);
                        3'd4: char_pixel = (x == 3'd0);
                        3'd5: char_pixel = (x == 3'd0);
                        3'd6: char_pixel = (x == 3'd0);
                        default: char_pixel = 1'b0;
                    endcase
                end

                // B
                CHAR_B: begin
                    case (y)
                        3'd0: char_pixel = (x <= 3'd3);
                        3'd1: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd2: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd3: char_pixel = (x <= 3'd3);
                        3'd4: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd5: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd6: char_pixel = (x <= 3'd3);
                        default: char_pixel = 1'b0;
                    endcase
                end

                // L
                CHAR_L: begin
                    case (y)
                        3'd0: char_pixel = (x == 3'd0);
                        3'd1: char_pixel = (x == 3'd0);
                        3'd2: char_pixel = (x == 3'd0);
                        3'd3: char_pixel = (x == 3'd0);
                        3'd4: char_pixel = (x == 3'd0);
                        3'd5: char_pixel = (x == 3'd0);
                        3'd6: char_pixel = (x <= 3'd4);
                        default: char_pixel = 1'b0;
                    endcase
                end

                // R
                CHAR_R: begin
                    case (y)
                        3'd0: char_pixel = (x <= 3'd3);
                        3'd1: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd2: char_pixel = (x == 3'd0) || (x == 3'd4);
                        3'd3: char_pixel = (x <= 3'd3);
                        3'd4: char_pixel = (x == 3'd0) || (x == 3'd2);
                        3'd5: char_pixel = (x == 3'd0) || (x == 3'd3);
                        3'd6: char_pixel = (x == 3'd0) || (x == 3'd4);
                        default: char_pixel = 1'b0;
                    endcase
                end

                // I
                CHAR_I: begin
                    case (y)
                        3'd0: char_pixel = (x <= 3'd4);
                        3'd1: char_pixel = (x == 3'd2);
                        3'd2: char_pixel = (x == 3'd2);
                        3'd3: char_pixel = (x == 3'd2);
                        3'd4: char_pixel = (x == 3'd2);
                        3'd5: char_pixel = (x == 3'd2);
                        3'd6: char_pixel = (x <= 3'd4);
                        default: char_pixel = 1'b0;
                    endcase
                end

                default: char_pixel = 1'b0;
            endcase
        end
    endfunction

    //==========================================================
    // Character placement helpers
    // each char is 5x7 logical pixels
    //==========================================================

    // Top row: FL, F, FR
    wire fl_f_en = (fb_x >= 8'd10)  && (fb_x <= 8'd14)  && (fb_y >= 7'd12) && (fb_y <= 7'd18);
    wire fl_l_en = (fb_x >= 8'd17)  && (fb_x <= 8'd21)  && (fb_y >= 7'd12) && (fb_y <= 7'd18);

    wire f_en    = (fb_x >= 8'd77)  && (fb_x <= 8'd81)  && (fb_y >= 7'd12) && (fb_y <= 7'd18);

    wire fr_f_en = (fb_x >= 8'd120) && (fb_x <= 8'd124) && (fb_y >= 7'd12) && (fb_y <= 7'd18);
    wire fr_r_en = (fb_x >= 8'd127) && (fb_x <= 8'd131) && (fb_y >= 7'd12) && (fb_y <= 7'd18);

    // Middle row: L, I, R
    wire l_en    = (fb_x >= 8'd10)  && (fb_x <= 8'd14)  && (fb_y >= 7'd56) && (fb_y <= 7'd62);

    wire i_en    = (fb_x >= 8'd77)  && (fb_x <= 8'd81)  && (fb_y >= 7'd56) && (fb_y <= 7'd62);

    wire r_en    = (fb_x >= 8'd127) && (fb_x <= 8'd131) && (fb_y >= 7'd56) && (fb_y <= 7'd62);

    // Bottom row: BL, B, BR
    wire bl_b_en = (fb_x >= 8'd10)  && (fb_x <= 8'd14)  && (fb_y >= 7'd96) && (fb_y <= 7'd102);
    wire bl_l_en = (fb_x >= 8'd17)  && (fb_x <= 8'd21)  && (fb_y >= 7'd96) && (fb_y <= 7'd102);

    wire b_en    = (fb_x >= 8'd77)  && (fb_x <= 8'd81)  && (fb_y >= 7'd96) && (fb_y <= 7'd102);

    wire br_b_en = (fb_x >= 8'd120) && (fb_x <= 8'd124) && (fb_y >= 7'd96) && (fb_y <= 7'd102);
    wire br_r_en = (fb_x >= 8'd127) && (fb_x <= 8'd131) && (fb_y >= 7'd96) && (fb_y <= 7'd102);

    // Local x/y inside each character
    wire [2:0] fl_f_x = fb_x - 8'd10;
    wire [2:0] fl_f_y = fb_y - 7'd12;

    wire [2:0] fl_l_x = fb_x - 8'd17;
    wire [2:0] fl_l_y = fb_y - 7'd12;

    wire [2:0] f_x    = fb_x - 8'd77;
    wire [2:0] f_y    = fb_y - 7'd12;

    wire [2:0] fr_f_x = fb_x - 8'd120;
    wire [2:0] fr_f_y = fb_y - 7'd12;

    wire [2:0] fr_r_x = fb_x - 8'd127;
    wire [2:0] fr_r_y = fb_y - 7'd12;

    wire [2:0] l_x    = fb_x - 8'd10;
    wire [2:0] l_y    = fb_y - 7'd56;

    wire [2:0] i_x    = fb_x - 8'd77;
    wire [2:0] i_y    = fb_y - 7'd56;

    wire [2:0] r_x    = fb_x - 8'd127;
    wire [2:0] r_y    = fb_y - 7'd56;

    wire [2:0] bl_b_x = fb_x - 8'd10;
    wire [2:0] bl_b_y = fb_y - 7'd96;

    wire [2:0] bl_l_x = fb_x - 8'd17;
    wire [2:0] bl_l_y = fb_y - 7'd96;

    wire [2:0] b_x    = fb_x - 8'd77;
    wire [2:0] b_y    = fb_y - 7'd96;

    wire [2:0] br_b_x = fb_x - 8'd120;
    wire [2:0] br_b_y = fb_y - 7'd96;

    wire [2:0] br_r_x = fb_x - 8'd127;
    wire [2:0] br_r_y = fb_y - 7'd96;

    // Character pixels
    wire letter_on;
    assign letter_on =
        (fl_f_en && char_pixel(CHAR_F, fl_f_x, fl_f_y)) ||
        (fl_l_en && char_pixel(CHAR_L, fl_l_x, fl_l_y)) ||

        (f_en    && char_pixel(CHAR_F, f_x, f_y)) ||

        (fr_f_en && char_pixel(CHAR_F, fr_f_x, fr_f_y)) ||
        (fr_r_en && char_pixel(CHAR_R, fr_r_x, fr_r_y)) ||

        (l_en    && char_pixel(CHAR_L, l_x, l_y)) ||
        (i_en    && char_pixel(CHAR_I, i_x, i_y)) ||
        (r_en    && char_pixel(CHAR_R, r_x, r_y)) ||

        (bl_b_en && char_pixel(CHAR_B, bl_b_x, bl_b_y)) ||
        (bl_l_en && char_pixel(CHAR_L, bl_l_x, bl_l_y)) ||

        (b_en    && char_pixel(CHAR_B, b_x, b_y)) ||

        (br_b_en && char_pixel(CHAR_B, br_b_x, br_b_y)) ||
        (br_r_en && char_pixel(CHAR_R, br_r_x, br_r_y));

    //==========================================================
    // Counter update
    //==========================================================
    always @(posedge CLK) begin
        if (h_cnt == HTs - 1) begin
            h_cnt <= 10'd0;

            if (v_cnt == VTs - 1)
                v_cnt <= 10'd0;
            else
                v_cnt <= v_cnt + 10'd1;
        end
        else begin
            h_cnt <= h_cnt + 10'd1;
        end
    end

    //==========================================================
    // Sync signals
    //==========================================================
    always @(posedge CLK) begin
        VGA_HS <= ~hs_active;
        VGA_VS <= ~vs_active;
    end

    //==========================================================
    // Framebuffer address
    //==========================================================
    always @(posedge CLK) begin
        VGA_ADDR <= {fb_y, fb_x};
    end

    //==========================================================
    // Delay display_on for memory alignment
    //==========================================================
    always @(posedge CLK) begin
        display_on_d <= display_on;
    end

    //==========================================================
    // Final colour selection
    // Priority:
    // 1. Grid
    // 2. Letters
    // 3. Framebuffer FG/BG
    //==========================================================
    always @(posedge CLK) begin
        if (display_on_d) begin
            if (grid_on)
                VGA_COLOUR <= GRID_COLOUR;
            else if (letter_on)
                VGA_COLOUR <= TEXT_COLOUR;
            else
                VGA_COLOUR <= (VGA_DATA) ? FG : BG;
        end
        else begin
            VGA_COLOUR <= 8'h00;
        end
    end

endmodule