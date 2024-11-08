module bounce_graph(
    input clk,  
    input reset,    
    input btn,        
    input gra_still,        // still graphics - newgame, game over states
    input [1:0] speed,
    input video_on,
    input [9:0] x,
    input [9:0] y,
    output graph_on,
    output reg hit, miss,   // ball hit or miss
    output reg [11:0] graph_rgb
    );
    
    // maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // create 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)
    
    //GROUND
    localparam rect_1_x1 = 0, rect_1_y1 = 260;
    localparam rect_1_x2 = 145, rect_1_y2 = 480;
    wire rectangle_1_on = (x >= rect_1_x1) && (x <= rect_1_x2) &&
                          (y >= rect_1_y1) && (y <= rect_1_y2);

    localparam rect_2_x1 = 170, rect_2_y1 = 260;
    localparam rect_2_x2 = 305, rect_2_y2 = 480;
    wire rectangle_2_on = (x >= rect_2_x1) && (x <= rect_2_x2) &&
                          (y >= rect_2_y1) && (y <= rect_2_y2);
                          
    localparam rect_3_x1 = 335, rect_3_y1 = 260;
    localparam rect_3_x2 = 470, rect_3_y2 = 480;
    wire rectangle_3_on = (x >= rect_3_x1) && (x <= rect_3_x2) &&
                          (y >= rect_3_y1) && (y <= rect_3_y2);
                          
    localparam rect_4_x1 = 500, rect_4_y1 = 260;
    localparam rect_4_x2 = 640, rect_4_y2 = 480;
    wire rectangle_4_on = (x >= rect_4_x1) && (x <= rect_4_x2) &&
                          (y >= rect_4_y1) && (y <= rect_4_y2);
    
    parameter SQ_RGB = 12'hFF0;             // Yellow color for square (red & green)
    parameter BG_RGB = 12'h007;             // Blue background
    parameter RECT_RGB = 12'h0FF;           // Rectangle color (aqua)
    parameter SQUARE_SIZE = 64;             // Width of square sides in pixels
    parameter SQUARE_VELOCITY_POS =2 ;      // Positive direction velocity
    parameter SQUARE_VELOCITY_NEG = -2;     // Negative direction velocity
    
    // BALL
    parameter BALL_SIZE = 8;			// square rom boundaries
    wire [9:0] x_ball_l, x_ball_r;		// ball horizontal boundary signals
    wire [9:0] y_ball_t, y_ball_b;		// ball vertical boundary signals
    reg [9:0] y_ball_reg, x_ball_reg;		// register to track top left position
    wire [9:0] y_ball_next, x_ball_next;	// signals for register buffer
    reg [9:0] x_delta_reg, x_delta_next;	// registers to track ball speed and buffers
    reg [9:0] y_delta_reg, y_delta_next;	// positive or negative ball velocity
    wire [2:0] rom_addr, rom_col;   		// 3-bit rom address and rom column
    reg [7:0] rom_data;             		// data at current rom address
    wire rom_bit;                   		// signify when rom data is 1 or 0 
						// for ball rgb control
	reg [1:0] speed_neg;
    reg btn_prev, slow_counter;			// Register Control
    reg ball_reset; 				// New signal to trigger ball reset

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_ball_reg <= 10;
            y_ball_reg <= 252;
            x_delta_reg <= 0;
            y_delta_reg <= 10'h000;
            btn_prev <= btn;
            slow_counter <= 0;
            //delay_counter <= 0;
            //delay_done <= 0;
        end
        else begin
            if (ball_reset) begin
                // Reset ball position when ball_reset is triggered
                x_ball_reg <= 10;
                y_ball_reg <= 252;
                x_delta_reg <= speed;
                y_delta_reg <= 10'h000;
            end
            else if (refresh_tick && (slow_counter == 0)) begin
                // Normal ball movement update
                //if(btn[1]) begin
                    x_ball_reg <= x_ball_next;
                    y_ball_reg <= y_ball_next;
                //end
            end
            
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
            btn_prev <= btn;
            slow_counter <= slow_counter + 1;
        end
    end    
    
    // ball rom
    always @*
        case(rom_addr)
            3'b000 :    rom_data = 8'b00111100; //   ****  
            3'b001 :    rom_data = 8'b01111110; //  ******
            3'b010 :    rom_data = 8'b11111111; // ********
            3'b011 :    rom_data = 8'b11111111; // ********
            3'b100 :    rom_data = 8'b11111111; // ********
            3'b101 :    rom_data = 8'b11111111; // ********
            3'b110 :    rom_data = 8'b01111110; //  ******
            3'b111 :    rom_data = 8'b00111100; //   ****
        endcase
     
    // OBJECT STATUS SIGNALS
    wire l_wall_on, t_wall_on, b_wall_on, pad_on, sq_ball_on, ball_on;
    wire [11:0] wall_rgb, pad_rgb, ball_rgb, bg_rgb;
    
    // pixel within wall boundaries
    //assign l_wall_on = ((L_WALL_L <= x) && (x <= L_WALL_R)) ? 1 : 0;
    //assign t_wall_on = ((T_WALL_T <= y) && (y <= T_WALL_B)) ? 1 : 0;
    //assign b_wall_on = ((B_WALL_T <= y) && (y <= B_WALL_B)) ? 1 : 0;
     
    // assign object colors
    assign wall_rgb   = 12'h0FF;    // blue walls
    assign ball_rgb   = 12'hF00;    // red ball
    assign bg_rgb     = 12'h007;    // aqua background
                    
    // rom data square boundaries
    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
    // pixel within rom square boundaries
    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    
    // map current pixel location to rom addr/col
    assign rom_addr = y[2:0] - y_ball_t[2:0];   // 3-bit address
    assign rom_col = x[2:0] - x_ball_l[2:0];    // 3-bit column index
    assign rom_bit = rom_data[rom_col];         // 1-bit signal rom data by column
    						// pixel within round ball
    assign ball_on = sq_ball_on & rom_bit;      // within square boundaries AND rom data bit == 1
 
  
    // Ball position updates
    assign x_ball_next = x_ball_reg + x_delta_reg;
    assign y_ball_next = y_ball_reg + y_delta_reg;
    
    // change ball direction after collision
    always @* begin
        hit = 1'b0;
        miss = 1'b0;
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        ball_reset = 1'b0;  // Default: no reset
    
        if(gra_still) begin
            x_delta_next = speed;
            y_delta_next = 0;
        end
    
        // Check if the ball falls into the pit
        if((y_ball_t >= 252) && (((x_ball_l >= 140) && (x_ball_r <= 170)) || ((x_ball_l >= 305) && (x_ball_r <= 335)) || ((x_ball_l >= 470) && (x_ball_r <= 500)))) begin
            y_delta_next = speed+2;
            x_delta_next = 0;
            miss = 1'b1;
    
            // Trigger ball reset when it reaches the bottom of the screen
            if(y_ball_t >= 472) begin
                ball_reset = 1'b1; // Set reset signal high
            end
        end else begin
            // Handle normal vertical movement (jump logic)
            if (btn_prev) begin
                if (y_ball_t <= 212)                   	// Top of jump
                    y_delta_next = speed; // Start descending
                else if (y_ball_t >= 252)              	// Bottom of jump
                    y_delta_next = -1*speed; // Ascend
            end else begin
                if (y_ball_t <= 212)                   	// Top of jump
                    y_delta_next = speed; // Descend
                else if (y_ball_t >= 252) begin        	// Stop vertical movement at ground level
                    y_delta_next = 0;
                    if ((y_ball_t >= 252) && (((x_ball_l >= 0) && (x_ball_r <= 145)) || ((x_ball_l >= 175) && (x_ball_r <= 305)) || ((x_ball_l >= 335) && (x_ball_r >= 470))))
                        hit = 1'b1;
                end
            end
    
            if (x_ball_l <= 0)                         // Left boundary
                x_delta_next = speed;    // Move right
            else if (x_ball_l >= X_MAX - BALL_SIZE)    // Right boundary
                x_delta_next = -1*speed;    // Move left
        end
    end

    // output status signal for graphics 
    assign graph_on = rectangle_1_on | rectangle_2_on | rectangle_3_on | rectangle_4_on | ball_on;
       
    // rgb multiplexing circuit
    always @*
        if(~video_on)
            graph_rgb = 12'h000;      // no value, blank
        else
            if(rectangle_1_on || rectangle_2_on || rectangle_3_on || rectangle_4_on)
                graph_rgb = wall_rgb;     // wall color
            else if(ball_on)
                graph_rgb = ball_rgb;     // ball color
            else
                graph_rgb = bg_rgb;       // background       
endmodule
