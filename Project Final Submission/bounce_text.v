module bounce_text(
    input clk,
    input [1:0] ball,
    input [3:0] dig0, dig1,
    input [9:0] x, y,
    output [2:0] text_on,
    output reg [11:0] text_rgb
    );
    
    // signal declaration
    wire [10:0] rom_addr;
    reg [6:0] char_addr, char_addr_s, char_addr_l, char_addr_r, char_addr_o;
    reg [3:0] row_addr;
    wire [3:0] row_addr_s, row_addr_l, row_addr_r, row_addr_o;
    reg [2:0] bit_addr;
    wire [2:0] bit_addr_s, bit_addr_l, bit_addr_r, bit_addr_o;
    wire [7:0] ascii_word;
    wire ascii_bit, score_on, logo_on, rule_on, over_on;
    wire [7:0] rule_rom_addr;
    
   // instantiate ascii rom
   ascii_rom ascii_unit(.clk(clk), .addr(rom_addr), .data(ascii_word));
   
    // --------------------------------------------------------------------------
    // logo region
    // - display logo "BOUNCE THE BALL" at top center
    // - scale to 64 by 128 text size
    // --------------------------------------------------------------------------
    assign logo_on = (y >= 64) && (y < 112) && (x >= 32 && x < 520);
    assign row_addr_l = y[5:2];             // Large font height
    assign bit_addr_l = x[4:2];             // Large font width
    always @* begin
        case (x[8:5]-1)
            4'h0: char_addr_l = 7'h42;      // B
            4'h1: char_addr_l = 7'h4F;      // O
            4'h2: char_addr_l = 7'h55;      // U
            4'h3: char_addr_l = 7'h4E;      // N
            4'h4: char_addr_l = 7'h43;      // C
            4'h5: char_addr_l = 7'h45;      // E
            4'h6: char_addr_l = 7'h20;      // Space
            4'h7: char_addr_l = 7'h54;      // T
            4'h8: char_addr_l = 7'h48;      // H
            4'h9: char_addr_l = 7'h45;      // E
            4'hA: char_addr_l = 7'h20;      // Space
            4'hB: char_addr_l = 7'h42;      // B
            4'hC: char_addr_l = 7'h41;      // A
            4'hD: char_addr_l = 7'h4C;      // L
            4'hE: char_addr_l = 7'h4C;      // L
            default: char_addr_l = 7'h00;   // Blank space
        endcase
    end        
    // --------------------------------------------------------------------------
    // rule and score region
    // - display rule (4 by 16 tiles) on center
    // - rule text:
    //     Rule:
    //     T18-JUMP
    //     T17-RESET
    //     Score: Ball:
    // --------------------------------------------------------------------------
    assign rule_on = (x[9:7] == 2) && (y[9:6] == 2);
    assign row_addr_r = y[3:0];
    assign bit_addr_r = x[2:0];
    assign rule_rom_addr = {y[5:4], x[6:3]};
    always @*
        case(rule_rom_addr)
            // row 1
            6'h00 : char_addr_r = 7'h52;    // R
            6'h01 : char_addr_r = 7'h55;    // U
            6'h02 : char_addr_r = 7'h4c;    // L
            6'h03 : char_addr_r = 7'h45;    // E
            6'h04 : char_addr_r = 7'h3A;    // :

            // row 2
            6'h10 : char_addr_r = 7'h54;    // T
            6'h11 : char_addr_r = 7'h31;    // 1
            6'h12 : char_addr_r = 7'h38;    // 8
            6'h13 : char_addr_r = 7'h2D;    // -
            6'h14 : char_addr_r = 7'h4A;    // J
            6'h15 : char_addr_r = 7'h55;    // U
            6'h16 : char_addr_r = 7'h4D;    // M
            6'h17 : char_addr_r = 7'h50;    // P
            
            // row 3
            6'h20 : char_addr_r = 7'h54;    // T
            6'h21 : char_addr_r = 7'h31;    // 1
            6'h22 : char_addr_r = 7'h37;    // 7
            6'h23 : char_addr_r = 7'h2D;    // -
            6'h24 : char_addr_r = 7'h52;    // R
            6'h25 : char_addr_r = 7'h45;    // E
            6'h26 : char_addr_r = 7'h53;    // S
            6'h27 : char_addr_r = 7'h45;    // E
            6'h28 : char_addr_r = 7'h54;    // T
            
            // row 4
            6'h30 : char_addr_r = 7'h53;    // S
            6'h31 : char_addr_r = 7'h43;    // C
            6'h32 : char_addr_r = 7'h4F;    // O
            6'h33 : char_addr_r = 7'h52;    // R
            6'h34 : char_addr_r = 7'h45;    // E
            6'h35 : char_addr_r = 7'h3A;    //:
            6'h36 : char_addr_r = {3'b011, dig1};    // tens digit    
            6'h37 : char_addr_r = {3'b011, dig0};    // ones digit    
            6'h38 : char_addr_r = 7'h00;    // 
            6'h39 : char_addr_r = 7'h42;    // B
            6'h3A : char_addr_r = 7'h41;    // A
            6'h3B : char_addr_r = 7'h4C;    // L
            6'h3C : char_addr_r = 7'h4C;    // L
            6'h3D : char_addr_r = 7'h3A;    // :
            6'h3E : char_addr_r = {5'b01100, ball};    
            default : char_addr_r = 7'h0;
        endcase
    // --------------------------------------------------------------------------
    // game over region
    // - display "GAME OVER" at center
    // - scale to 32 by 64 text size
    // --------------------------------------------------------------------------
    assign over_on = (y[9:6] == 3) && (5 <= x[9:5]) && (x[9:5] <= 13);
    assign row_addr_o = y[5:2];
    assign bit_addr_o = x[4:2];
    always @*
        case(x[8:5])
            4'h5 : char_addr_o = 7'h47;     // G
            4'h6 : char_addr_o = 7'h41;     // A
            4'h7 : char_addr_o = 7'h4D;     // M
            4'h8 : char_addr_o = 7'h45;     // E
            4'h9 : char_addr_o = 7'h00;     //
            4'hA : char_addr_o = 7'h4F;     // O
            4'hB : char_addr_o = 7'h56;     // V
            4'hC : char_addr_o = 7'h45;     // E
            4'hD : char_addr_o = 7'h52;     // R
            default : char_addr_o = 7'h0;  
        endcase
    
    // mux for ascii ROM addresses and rgb
    always @* begin
        text_rgb = 12'h007;     // BLUE background
        
        if(score_on) begin
            char_addr = char_addr_s;
            row_addr = row_addr_s;
            bit_addr = bit_addr_s;
            if(ascii_bit)
                text_rgb = 12'hFFF; // RED
        end
        
        else if(rule_on) begin
            char_addr = char_addr_r;
            row_addr = row_addr_r;
            bit_addr = bit_addr_r;
            if(ascii_bit)
                text_rgb = 12'hF00; // RED
        end
        
        else if(logo_on) begin
            char_addr = char_addr_l;
            row_addr = row_addr_l;
            bit_addr = bit_addr_l;
            if(ascii_bit)
                text_rgb = 12'hFF0; // YELLOW
        end
        
        else if (over_on) begin
            char_addr = char_addr_o;
            row_addr = row_addr_o;
            bit_addr = bit_addr_o;
            if(ascii_bit)
                text_rgb = 12'hF00; // RED
        end        
    end
    
    assign text_on = {score_on, logo_on, rule_on, over_on};
    
    // ascii ROM interface
    assign rom_addr = {char_addr, row_addr};
    assign ascii_bit = ascii_word[~bit_addr];      
endmodule
