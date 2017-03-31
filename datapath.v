
module Final_Project(CLOCK_50, LEDR, SW, KEY, LEDG, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
	VGA_CLK,  //	VGA Clock
	VGA_HS,   //	VGA H_SYNC
	VGA_VS,	//	VGA V_SYNC
	VGA_BLANK_N,//	VGA BLANK
	VGA_SYNC_N,//	VGA SYNC
	VGA_R,   	//	VGA Red[9:0]
	VGA_G,	 //	VGA Green[9:0]
	VGA_B);
	input CLOCK_50;
	input [17:0] SW;
	input [3:0] KEY;
	output [17:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [6:0] HEX6;
	output [6:0] HEX7;
	output	VGA_CLK;  //	VGA Clock
	output	VGA_HS;   //	VGA H_SYNC
	output	VGA_VS;   //	VGA V_SYNC
	output	VGA_BLANK_N; //	VGA BLANK
	output	VGA_SYNC_N;  //	VGA SYNC
	output	[9:0]	VGA_R;  //	VGA Red[9:0]
	output	[9:0]	VGA_G;  //	VGA Green[9:0]
	output	[9:0]	VGA_B;  //	VGA Blue[9:0]
			
	wire [3:0] h0, h1, h2, h3, h4, h5, h6, h7;
	wire [7:0] hhg;
	
	// Register for the RAM
    wire [7:0] address_input;
    wire [3:0] data_input;
    wire [3:0] data_output;
    wire storing_enable;
	 wire[4:0] empty1, empty2,empty3;
	 
	ram256x4 ram(address_input, CLOCK_50, data_input, storing_enable, data_output);
	
	wire [7:0] map_to_address_input;
	wire [3:0] map_to_data_input;
	wire map_storing_enable;
	wire [4:0] vga_yin;
	wire [4:0] vga_xin;
	wire[2:0] vga_col;
	
	mil_25_counter clasdo(CLOCK_50, SW[17], 1, clk_20);
	
	reset_map to_default_map(.clk(clk_20),
                             .resetn(SW[17]),
                             
                             // OUTPUT to "RAM"
                             .address_output(map_to_address_input),
                             .data_output(map_to_data_input),
                             .storing_enable(map_storing_enable),
                             
                             // OUTPUT to "VGA"
                             .vga_out_x(vga_xin),
                             .vga_out_y(vga_yin),
                             .vga_cell_type(vga_col));
									  
	assign address_output = map_to_address_input;
   assign data_output = map_to_data_input;
   assign storing_enable = map_storing_enable;
	
	wire [2:0] colour;
	wire [6:0] x;
	wire [6:0] y;
	wire writeEn;
	
		vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";		
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require
									  
								
	wire xloaden;
	wire [3:0] countval;
	vgadatapath d0(
			.resetn(SW[17]),
			.clock(CLOCK_50),
			.xload(xloaden),
			.writeEn(writeEn),
			.cin(vga_col),
			.xin(vga_xin),
			.yin(vga_yin),
			.cout(colour),
			.xout(x),
			.yout(y),
			.countval(countval));
    // Instansiate FSM control
    // control c0(...);
    vgacontrol c0(
			.resetn(resetn),
			.clk(CLOCK_50),
			.go(KEY[1]),
			.xload(KEY[3]),
			.writeEnPress(KEY[1]),
			.countval(countval),
			.xloaden(xloaden),
			.writeEn(writeEn));
	
	
endmodule

module datapath(clk,           // CLOCK_50/16
                resetn,        // Active Low reset for everything
                
                /* DATA INPUT from "pcontrol" */
                in_player_x,   // The x coordinate of the player
                in_player_y,   // The y coordinate of the player
                p_bomb_x,      // The x coordinate of the newly placed bomb
                p_bomb_y,      // The y coordinate of the newly placed bomb
                ld_player_x,   // When x coordinate of the player is ready to be read
                ld_player_y,   // When y coordinate of the player is ready to be read
                plot_p,        // When the coordinate for the player can be plotted
                ld_bomb,       // Trigger for reading the coordinate of the bomb
                
                /* DATA OUTPUT to "pcontrol" */
                out_player_x,  // Current position of the player
                out_player_y,  // Current position of the player
                player_up,     // The type of cell on top of the palyer
                player_down,   // The type of cell below the player
                player_left,   // The type of cell to the left of the player
                player_right,  // The type of cell to the right of the player
                bomb_exp,      // When a bomb explodes return 1 for that clk cycle
                
                /* DATA INPUT from "FSM_BOMB" */
                in_fsm_x,      // The x coordinate for the cell the FSM_BOMB needs
                in_fsm_y,      // The y coordinate for the cell the FSM_BOMB needs
                plot_fsm,      // Enabler for ploting the address after explosion
                ld_bomb_num,   // The bomb # the FSM_BOMB want in return
                fsm_cell_in,   // The new cell to overwrite old item given by (in_fsm_x, in_fsm_y)
                fsm_mode,      // The mode the fsm is currently in; either 'get' or 'set'
                
                /* DATA OUTPUT  to "FSM_BOMB" */
                out_fsm_x,     // x coordinate for the given bomb #
                out_fsm_y,     // y coordinate for the given bomb #
                out_fsm_cell,  // The item at (in_fsm_x, in_fsm_y)
                
                /* DATA OUTPUT to "VGA" */
                vga_out_x,     // The x coordinate of a certain cell
                vga_out_y,     // The y coordinate of a certain cell
                vga_cell_type);// The type of the cell pointed to by (out_x, out_y)
                
    
    input clk;
    input resetn;
    
    /* DATA INPUT from "pcontrol" */
    input [4:0] in_player_x;
    input [4:0] in_player_y;
    input [4:0] p_bomb_x;
    input [4:0] p_bomb_y;
    input ld_player_x;
    input ld_player_y;
    input plot_p;
    input ld_bomb;
    
    /* DATA OUTPUT to "pcontrol" */
    output reg [4:0] out_player_x;
    output reg [4:0] out_player_y;
    output reg [2:0] player_up;
    output reg [2:0] player_down;
    output reg [2:0] player_left;
    output reg [2:0] player_right;
    output reg bomb_exp;
    
    /* DATA INPUT from "FSM_BOMB" */
    input [4:0] in_fsm_x;      
    input [4:0] in_fsm_y;  
    input plot_fsm;
    input [2:0] ld_bomb_num;  
    input [2:0] fsm_cell_in;  
    input [2:0] fsm_mode;      
    
    /* DATA OUTPUT  to "FSM_BOMB" */
    output [4:0] out_fsm_x;
    output [4:0] out_fsm_y;
    output reg [2:0] out_fsm_cell;
    
    /* DATA OUTPUT to "vga" */
    output reg [4:0] vga_out_x;
    output reg [4:0] vga_out_y;
    output reg [2:0] vga_cell_type;
    
    // Register for the RAM
    wire [7:0] address_input;
    wire [3:0] data_input;
    wire [3:0] data_output;
    wire storing_enable;
    
    // Register for the six bombs
    reg [9:0] bomb0_coor;
    reg [9:0] bomb1_coor;
    reg [9:0] bomb2_coor;
    reg [9:0] bomb3_coor;
    reg [9:0] bomb4_coor;
    reg [9:0] bomb5_coor;
    
    /* DIFFERENT TYPE OF CELL */
    localparam TILE = 3'b000;
    localparam PLAYER = 3'b001;
    localparam WALL = 3'b010;
    localparam BLOCK = 3'b011;
    localparam BOMB = 3'b100;
    
    /* RAM (Memmory) */
    localparam BITS_PER_CELL = 3'd4;
    localparam NUMBER_OF_ROWS = 4'd9;
    localparam NUMBER_OF_COLUMNS = 4'd11;
    
    
    /*****************************************************************************/
    /* Creating the RAM (Memmory) to store ALL CELLS in the map */
    /*****************************************************************************/
    ram256x4 ram(address_input, clk, data_input, storing_enable, data_output);
    
    
    /*****************************************************************************/
    /* Reading and setting the coordinate of the player */
    /*****************************************************************************/
    movement_of_player player(.clk(clk),
                              .resetn(resetn),
                              // Input from "pcontrol"
                              .in_player_x(in_player_x),
                              .in_player_y(in_player_y),
                              .ld_player_x(ld_player_x),
                              .ld_player_y(ld_player_y),
                              .plot_p(plot_p),
                              .ld_bomb(ld_bomb),
                              // Input from the "VGA"
                              .ram_cell_info(data_output),
                              // Output to the "pcontrol"
                              .out_player_x(out_player_x),
                              .out_player_y(out_player_x),
                              .p_up(player_up),
                              .p_down(player_down),
                              .p_left(player_left),
                              .p_right(player_right),
                              // Output to the "VGA"
                              .vga_out_x(vga_out_x),
                              .vga_out_y(vga_out_y),
                              .vga_cell_type(vga_cell_type),
                              // Output to the "RAM"
                              .address_input(address_input),
                              .data_input(data_input),
                              .storing_enable(storing_enable));
                              
                              
    /*****************************************************************************/
    /* Reading and setting the coordinate of the 6 bomb */
    /*****************************************************************************/
    set_coordinate_of_bombs bomb_6(.clk(clk),
                                   .resetn(resetn),
                                   // Input from "pcontrol"
                                   .p_bomb_x(p_bomb_x),
                                   .p_bomb_y(p_bomb_y),
                                   .ld_bomb(ld_bomb),
                                   // Input of the regester repersenting the 6 bombs
                                   .bomb0_coor(bomb0_coor),
                                   .bomb1_coor(bomb1_coor),
                                   .bomb2_coor(bomb2_coor),
                                   .bomb3_coor(bomb3_coor),
                                   .bomb4_coor(bomb4_coor),
                                   .bomb5_coor(bomb5_coor),
                                   // Output to the "VGA"
                                   .vga_out_x(vga_out_x),
                                   .vga_out_y(vga_out_y),
                                   .vga_cell_type(vga_cell_type),
                                   // Output to the "RAM"
                                   .address_input(address_input),
                                   .data_input(data_input),
                                   .storing_enable(storing_enable));
                               
                               
    /*****************************************************************************/
    /* Outputing the Cell to FSM_BOMB with the given coordinates */
    /*****************************************************************************/
    get_cell_at_coordinate get_cell(.clk(clk),
                                    .resetn(resetn),
                                  
                                    // INPUT from "FSM_BOMB"
                                    .fsm_mode(fsm_mode),
                                    .in_fsm_x(in_fsm_x),
                                    .in_fsm_y(in_fsm_y),
                                    .ram_in_cell_type(data_output),
                                  
                                    // OUTPUT to "FSM_BOMB"
                                    .out_cell_type(out_fsm_cell),
                                    .address_input(address_input),
                                    .storing_enable(storing_enable));
                                    
    
    /*****************************************************************************/
    /* Outputing the coordinate of the bomb, provided its number */
    /*****************************************************************************/
    get_coordinate_of_bomb get_bomb_coor(.clk(clk),
                                         .resetn(resetn),
                                          
                                          // INPUT of all six bomb
                                         .bomb0_coor(bomb0_coor),
                                         .bomb1_coor(bomb1_coor),
                                         .bomb2_coor(bomb2_coor),
                                         .bomb3_coor(bomb3_coor),
                                         .bomb4_coor(bomb4_coor),
                                         .bomb5_coor(bomb5_coor),
                                          
                                          // INPUT from "FSM_BOMB"
                                         .bomb_num(ld_bomb_num),
                                         .fsm_mode(fsm_mode),
                                          
                                          // OUTPUT to "FSM_BOMB"
                                         .out_fsm_x(out_fsm_x),
                                         .out_fsm_y(out_fsm_y));
                                         
    /*****************************************************************************/
    /* Set the cell_type for the specific location */
    /*****************************************************************************/
    after_explosion explosion(.clk(clk),
                              .resetn(resetn),
                               
                              // INPUT from "FSM_BOMB"
                              .fsm_mode(fsm_mode),
                              .new_cell_type(fsm_cell_in),
                              .in_fsm_x(in_fsm_x),
                              .in_fsm_y(in_fsm_y),
                              .plot_new_cell(plot_fsm),
                              .ld_bomb_num(ld_bomb_num),
                              
                              // OUTPUT of all six bomb
                              .bomb0_coor(bomb0_coor),
                              .bomb1_coor(bomb1_coor),
                              .bomb2_coor(bomb2_coor),
                              .bomb3_coor(bomb3_coor),
                              .bomb4_coor(bomb4_coor),
                              .bomb5_coor(bomb5_coor),
                        
                              // OUTPUT to "VGA"
                              .vga_out_x(vga_out_x),
                              .vga_out_y(vga_out_y),
                              .vga_cell_type(vga_cell_type),
                               
                              // OUTPUT to "RAM"
                              .address_output(address_input),
                              .data_output(data_input),
                              .storing_enable(storing_enable));
                              
                              
    /*****************************************************************************/
    /* Reset the current map to the default map when there is an active low */
    /* reset */
    /*****************************************************************************/
    reset_map to_default_map(.clk(clk),
                             .resetn(resetn),
                             
                             // OUTPUT to "RAM"
                             .address_output(address_input),
                             .data_output(data_input),
                             .storing_enable(storing_enable),
                             
                             // OUTPUT to "VGA"
                             .vga_out_x(vga_out_x),
                             .vga_out_y(vga_out_y),
                             .vga_cell_type(vga_cell_type));
endmodule


/*****************************************************************************/
/* Reading and setting the coordinate of the player */
/*****************************************************************************/
module movement_of_player(clk,
                          resetn,
                          // Input from "pcontrol"
                          in_player_x,
                          in_player_y,
                          ld_player_x,
                          ld_player_y,
                          plot_p,
                          ld_bomb,
                          // Input from the "VGA"
                          ram_cell_info,
                          // Output to the "pcontrol"
                          out_player_x,
                          out_player_y,
                          p_up,
                          p_down,
                          p_left,
                          p_right,
                          // Output to the "VGA"
                          vga_out_x,
                          vga_out_y,
                          vga_cell_type,
                          // Output to the "RAM"
                          address_input,
                          data_input,
                          storing_enable);
    
    input clk;
    input resetn;
    
    /* DATA RETREAVE from "pcontrol" */
    input [4:0] in_player_x;
    input [4:0] in_player_y;
    input ld_player_x;
    input ld_player_y;
    input plot_p;
    input ld_bomb;
    
    /* CELL DATA from the RAM (Memory) */
    input [2:0] ram_cell_info;
    
    // bomb_droped is used to check if player droped
    // the bomb before moving or not.
    reg bomb_droped;
    
    // Output to the "pcontrol"
    output reg [4:0] out_player_x;
    output reg [4:0] out_player_y;
    output reg [2:0] p_up;
    output reg [2:0] p_down;
    output reg [2:0] p_left;
    output reg [2:0] p_right;
                          
    /* DATA RETURN to "vga" */
    output reg [4:0] vga_out_x;
    output reg [4:0] vga_out_y;
    output reg [2:0] vga_cell_type;
    
    /* DATA to the RAM (Memory) */
    output reg [7:0] address_input;
    output reg [3:0] data_input;
    output reg storing_enable;
    
    /* DIFFERENT TYPE OF CELL */
    localparam TILE = 3'b000;
    localparam PLAYER = 3'b001;
    localparam WALL = 3'b010;
    localparam BLOCK = 3'b011;
    localparam BOMB = 3'b100;
    
    /* RAM (Memmory) */
    localparam BITS_PER_CELL = 3'd4;
    localparam NUMBER_OF_ROWS = 4'd9;
    localparam NUMBER_OF_COLUMNS = 4'd11;
    
    // PLAYER POSITION
    localparam DEFAULT_PLAYER_ADDRESS = NUMBER_OF_COLUMNS;
    localparam DEFAULT_PLAYER_X = 5'd1;
    localparam DEFAULT_PLAYER_Y = 5'd1;
    reg [7:0] curr_player_address;
    reg [4:0] curr_player_x;
    reg [4:0] curr_player_y;
    reg [7:0] pre_player_address;
    reg [4:0] pre_player_x;
    reg [4:0] pre_player_y;

    
    reg [2:0] player_ld_counter = 3'd0;
    wire player_ld_counter_clear;
    // Player Movement
    always @(posedge clk or negedge resetn)
    begin: player_ld_coordinates
        
        // Move player to the default position.
        if(!resetn)
        begin
            // storing_enable <= 1'b1;
            // address_input <= DEFAULT_PLAYER_ADDRESS;
            // data_input <= PLAYER;
				
            player_ld_counter <= 3'd0;
				
            // Set curr_player_address to default.
            curr_player_address <= DEFAULT_PLAYER_ADDRESS;
            curr_player_x <= DEFAULT_PLAYER_X;
            curr_player_y <= DEFAULT_PLAYER_Y;
            
            // Tell VGA about the reset.
            vga_out_x = DEFAULT_PLAYER_X;
            vga_out_y = DEFAULT_PLAYER_Y;
            vga_cell_type = PLAYER;
            
			// Set the curr_player coordinates to out_player_x, out_player_y.
			out_player_x = DEFAULT_PLAYER_X;
            out_player_y = DEFAULT_PLAYER_Y;
				
            // Set pre_player_address to default.
            // And start the 4 step assign for p_up, p_down, p_left and p_right.
            // Therefore set player_ld_counter to "3'd2".
            player_ld_counter <= 3'd2;
        end
        // When in_player_x and in_player_y are ready.
        // Store the new location of the player after the movement.
        else if((ld_player_x == 1'b1) & (ld_player_y == 1'b1))
        begin
            storing_enable = 1'b1;
            address_input = (NUMBER_OF_COLUMNS * in_player_y) + in_player_x;
            data_input = PLAYER;
            
            // Set curr_player_address.
            curr_player_address <= (NUMBER_OF_COLUMNS * in_player_y) + in_player_x;
            curr_player_x <= in_player_x;
            curr_player_y <= in_player_y;
            
            // Set the curr_player coordinates to out_player_x, out_player_y.
            out_player_x = in_player_x;
            out_player_y = in_player_y;
            
            // Plot the player in current coordinates
            vga_out_x = in_player_x;
            vga_out_y = in_player_y;
            vga_cell_type = PLAYER;
            
            // START of the three step player movement.
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        // Setting the old location of the player to a TILE or BOMB.
        else if(player_ld_counter == 3'd1)
        begin
            storing_enable = 1'b1;
            address_input = pre_player_address;
            
            // If there is a bomb droped before moving.
            if(bomb_droped == 1'b0)
			begin
                data_input = TILE;
                vga_cell_type = TILE;
			end
            else
				begin
                data_input = BOMB;
                vga_cell_type = BOMB;
			   end
            
            // Tell the VGA about the old location of the player.
            vga_out_x = pre_player_x;
            vga_out_y = pre_player_y;
            
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        // Setting the pre_player_position to the curr_player_position.
        // And start setting the p_up, p_down, p_left, and p_right of the
        // new curr_player_address. (count to 4 including this one)
        else if(player_ld_counter == 3'd2)
        begin
            pre_player_address <= curr_player_address;
            pre_player_x <= curr_player_x;
            pre_player_y <= curr_player_y;
            
            // Set the address for p_up. Wait for a clk cycle to get result!
            storing_enable = 1'b0;
            address_input = (curr_player_address - NUMBER_OF_COLUMNS);
            
				/*
            // Set bomb_droped to 1'b0, because after one clk cycle,
            // the pre_player_address should be stored with either a TILE or a
            // BOMB.
            bomb_droped = 1'b0;
            */
				
            // End of the three step player movement.
            // START of the 4 step assign for p_up, p_down, p_left and p_right.
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        else if(player_ld_counter == 3'd3)
        begin
            // Set p_up.
            p_up = ram_cell_info;
            // Set the address for p_down. Wait for a clk cycle to get result!
            storing_enable = 1'b0;
            address_input = (curr_player_address + NUMBER_OF_COLUMNS);
				
			// didn't droped bomb.
			bomb_droped <= 1'b0;
            
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        else if(player_ld_counter == 3'd4)
        begin
            // Set p_down.
            p_down = ram_cell_info;
            // Set the address for p_left. Wait for a clk cycle to get result!
            storing_enable = 1'b0;
            address_input = (curr_player_address  - 1'b1);
            
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        else if(player_ld_counter == 3'd5)
        begin
            // Set p_left.
            p_left = ram_cell_info;
            // Set the address for p_right. Wait for a clk cycle to get result!
            storing_enable = 1'b0;
            address_input = (curr_player_address  + 1'b1);
            
            player_ld_counter <= player_ld_counter + 1'b1;
        end
        // END of the 4 step assign for p_up, p_down, p_left and p_right.
        else if(player_ld_counter == 3'd6)
        begin
            // Set p_left.
            p_left = ram_cell_info;
            
            // END of the 4 step assign for p_up, p_down, p_left and p_right.
            player_ld_counter <= 3'd0;
        end
		  
		if(!resetn)
			bomb_droped <= 1'b1;
		else if(ld_bomb == 1'b1)
            bomb_droped <= 1'b1;
				
    end
    
    
	 /*
    // Updating the player_ld_counter.
    // This is a counter that moves the player from one position to another.
    // Then assign for p_up, p_down, p_left and p_right.
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
            player_ld_counter = 3'd0;
        else if(player_ld_counter_clear)
            player_ld_counter = 3'd0;
    end
    assign player_ld_counter_clear = (player_ld_counter == 3'd7);
	 */
    
    
	 /*
    // A always block that set bomb_droped to 1'b1 when there is one clk
    // cycle where ld_bomb == 1'b1.
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
            bomb_droped <= 1'b1;
        else if(ld_bomb == 1'b1)
            bomb_droped <= 1'b1;
    end
	 */
endmodule


/*****************************************************************************/
/* Reading and setting the coordinate of the 6 bomb */
/*****************************************************************************/
module set_coordinate_of_bombs(clk,
                               resetn,
                               // Input from "pcontrol"
                               p_bomb_x,
                               p_bomb_y,
                               ld_bomb,
                               // Output of the regester repersenting the 6 bombs
                               bomb0_coor,
                               bomb1_coor,
                               bomb2_coor,
                               bomb3_coor,
                               bomb4_coor,
                               bomb5_coor,
                               // Output to the "VGA"
                               vga_out_x,
                               vga_out_y,
                               vga_cell_type,
                               // Output to the "RAM"
                               address_input,
                               data_input,
                               storing_enable);
                           
    input clk;
    input resetn;
    
    /* Input from "pcontrol" */
    input [4:0] p_bomb_x;
    input [4:0] p_bomb_y;
    input ld_bomb;
    
    /* Output of the regester repersenting the 6 bombs */
    output reg [9:0] bomb0_coor;
    output reg [9:0] bomb1_coor;
    output reg [9:0] bomb2_coor;
    output reg [9:0] bomb3_coor;
    output reg [9:0] bomb4_coor;
    output reg [9:0] bomb5_coor;
    
    /* DATA RETURN to "VGA" */
    output reg [4:0] vga_out_x;
    output reg [4:0] vga_out_y;
    output reg [2:0] vga_cell_type;
    
    /* DATA to the RAM (Memory) */
    output reg [7:0] address_input;
    output reg [3:0] data_input;
    output reg storing_enable;
    
    /* DIFFERENT TYPE OF CELL */
    localparam TILE = 3'b000;
    localparam PLAYER = 3'b001;
    localparam WALL = 3'b010;
    localparam BLOCK = 3'b011;
    localparam BOMB = 3'b100;
    
    
    // To check wether the bomb at that location exist or not.
    reg bomb_exist;
    
    always @(posedge clk or negedge resetn)
    begin
        // When there is a active low resetn then set all bombs to a
        // not possible coordinate; which is 10'b1111111111.
        if(!resetn)
        begin
            bomb0_coor <= 10'b1111111111;
            bomb1_coor <= 10'b1111111111;
            bomb2_coor <= 10'b1111111111;
            bomb3_coor <= 10'b1111111111;
            bomb4_coor <= 10'b1111111111;
            bomb5_coor <= 10'b1111111111;
        end
        // else if ld_bomb = 1'b1 (just placed a bomb)
        // then check which bomb# != 10'b1111111111.
        // Find that bomb# and set it to p_bomb_x and p_bomb_y
        // iff there are no other bombs at the name coordinate.
        else if(ld_bomb)
        begin
            if(bomb0_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else if(bomb1_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else if(bomb2_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else if(bomb3_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else if(bomb4_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else if(bomb5_coor == {p_bomb_x, p_bomb_y})
                bomb_exist <= 1'b1;
            else
                bomb_exist <= 1'b0;
        end
        // iff bomb_exist == 1'b0 place the new bomb.
        else if(bomb_exist == 1'b0)
        begin
            // Set bomb_exist back to 1'b1 because we don't want
            // to go into this else if every block cycle.
            bomb_exist <= 1'b1;
            
            // Try setting the new bomb.
            if(bomb0_coor == 10'b1111111111)
            begin
                bomb0_coor[9:5] <= p_bomb_x;
                bomb0_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            else if(bomb1_coor == 10'b1111111111)
            begin
                bomb1_coor[9:5] <= p_bomb_x;
                bomb1_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            else if(bomb2_coor == 10'b1111111111)
            begin
                bomb2_coor[9:5] <= p_bomb_x;
                bomb2_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            else if(bomb3_coor == 10'b1111111111)
            begin
                bomb3_coor[9:5] <= p_bomb_x;
                bomb3_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            else if(bomb4_coor == 10'b1111111111)
            begin
                bomb4_coor[9:5] <= p_bomb_x;
                bomb4_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            else if(bomb5_coor == 10'b1111111111)
            begin
                bomb5_coor[9:5] <= p_bomb_x;
                bomb5_coor[4:0] <= p_bomb_y;
                
                // Tell VGA to print the bomb out.
                vga_out_x <= p_bomb_x;
                vga_out_y <= p_bomb_y;
                vga_cell_type <= BOMB;
                
                // Storing the position of the BOMB?
                // This is already done in the movement of player module.
            end
            // If none of the if statement above is true then the player can
            // not place more bombs.
        end
    end
endmodule


/*****************************************************************************/
/* Outputing the Cell to FSM_BOMB with the given coordinates */
/*****************************************************************************/
module get_cell_at_coordinate(clk,
                              resetn,
                              
                              // INPUT from "FSM_BOMB"
                              fsm_mode,
                              in_fsm_x,
                              in_fsm_y,
                              ram_in_cell_type,
                              
                              // OUTPUT to "FSM_BOMB"
                              out_cell_type,
                              address_input,
                              storing_enable);
    
    input clk;
    input resetn;
    
    // INPUT from "FSM_BOMB"
    input [2:0] fsm_mode;
    input [4:0] in_fsm_x;
    input [4:0] in_fsm_y;
    input [3:0] ram_in_cell_type;
  
    // OUTPUT to "FSM_BOMB"
    output reg [2:0] out_cell_type;
    output reg [7:0] address_input;
    output reg storing_enable;
                              
    /* RAM (Memmory) */
    localparam BITS_PER_CELL = 3'd4;
    localparam NUMBER_OF_ROWS = 4'd9;
    localparam NUMBER_OF_COLUMNS = 4'd11;
    
    
    // When check fsm_mode for each posedge clk.
    // When fsm_mode == 3'b001 (get) then set out_cell_type.
    // Create a counter that can count to three because we need a clk
    // cycle enable to receive the ram_in_cell_type from the RAM (Memmory).
    reg [1:0] clk_counter = 2'd0;
    wire clk_counter_clear;
    always @(posedge clk)
    begin
        // If fsm_mode is set to 'get' and the counter is 0 and it is
        // currently not reseting because the map_reset sets the
        // storing_enable to 1'b1. And nothing here should do anything
        // when reseting.
        if(((fsm_mode == 3'b001) && (clk_counter == 2'd0)) && (resetn))
        begin
            storing_enable <= 1'b0;
            address_input <= (NUMBER_OF_COLUMNS * in_fsm_y) + in_fsm_x;
            
            // Wait a clk cycle to receive the currect ram_in_cell_type.
            clk_counter = clk_counter + 1'b1;
        end
        // Set out_cell_type.
        else if(clk_counter == 2'd1)
        begin
            out_cell_type <= ram_in_cell_type[2:0];
            
            // Ready the clk_counter for reset.
            clk_counter = clk_counter + 1'b1;
        end
    end
    
    // The counter for clk_counter.
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
            clk_counter <= 2'd0;
        else if(clk_counter_clear)
            clk_counter <= 2'd0;
    end
    assign clk_counter_clear = (clk_counter == 2'd2);
endmodule
        

/*****************************************************************************/
/* Outputing the coordinate of the bomb, provided its number */
/*****************************************************************************/
module get_coordinate_of_bomb(clk,
                              resetn,
                              
                              // INPUT of all six bomb
                              bomb0_coor,
                              bomb1_coor,
                              bomb2_coor,
                              bomb3_coor,
                              bomb4_coor,
                              bomb5_coor,
                              
                              // INPUT from "FSM_BOMB"
                              bomb_num,
                              fsm_mode,
                              
                              // OUTPUT to "FSM_BOMB"
                              out_fsm_x,
                              out_fsm_y);
                              
    input clk;
    input resetn;
    
    // INPUT of all six bomb
    input [9:0] bomb0_coor;
    input [9:0] bomb1_coor;
    input [9:0] bomb2_coor;
    input [9:0] bomb3_coor;
    input [9:0] bomb4_coor;
    input [9:0] bomb5_coor;
  
    // INPUT from "FSM_BOMB"
    input [2:0] bomb_num;
    input [2:0] fsm_mode;
  
    // OUTPUT to "FSM_BOMB"
    output reg [4:0] out_fsm_x;
    output reg [4:0] out_fsm_y;
    
    always @(posedge clk)
    begin
        if(fsm_mode == 3'b001)
        begin
            if(bomb_num == 3'd0)
            begin
                out_fsm_x <= bomb0_coor[9:5];
                out_fsm_y <= bomb0_coor[4:0];
            end
            else if(bomb_num == 3'd1)
            begin
                out_fsm_x <= bomb1_coor[9:5];
                out_fsm_y <= bomb1_coor[4:0];
            end
            else if(bomb_num == 3'd2)
            begin
                out_fsm_x <= bomb2_coor[9:5];
                out_fsm_y <= bomb2_coor[4:0];
            end
            else if(bomb_num == 3'd3)
            begin
                out_fsm_x <= bomb3_coor[9:5];
                out_fsm_y <= bomb3_coor[4:0];
            end
            else if(bomb_num == 3'd4)
            begin
                out_fsm_x <= bomb4_coor[9:5];
                out_fsm_y <= bomb4_coor[4:0];
            end
            else if(bomb_num == 3'd5)
            begin
                out_fsm_x <= bomb5_coor[9:5];
                out_fsm_y <= bomb5_coor[4:0];
            end
        end
    end
endmodule


/*****************************************************************************/
/* Set the cell_type for the specific location */
/*****************************************************************************/
module after_explosion(clk,
                       resetn,
                       
                       // INPUT from "FSM_BOMB"
                       fsm_mode,
                       new_cell_type,
                       in_fsm_x,
                       in_fsm_y,
                       plot_new_cell,
                       ld_bomb_num,
                       
                       // OUTPUT of all six bomb
                       bomb0_coor,
                       bomb1_coor,
                       bomb2_coor,
                       bomb3_coor,
                       bomb4_coor,
                       bomb5_coor,
                              
                       // OUTPUT to "VGA"
                       vga_out_x,
                       vga_out_y,
                       vga_cell_type,
                       
                       // OUTPUT to "RAM"
                       address_output,
                       data_output,
                       storing_enable);
                       
    input clk;
    input resetn;
    
    // INPUT from "FSM_BOMB"
    input [2:0] fsm_mode;
    input [2:0] new_cell_type;
    input [4:0] in_fsm_x;
    input [4:0] in_fsm_y;
    input plot_new_cell;
    input [2:0] ld_bomb_num;
    
    // OUTPUT of all six bomb
    output reg [9:0] bomb0_coor;
    output reg [9:0] bomb1_coor;
    output reg [9:0] bomb2_coor;
    output reg [9:0] bomb3_coor;
    output reg [9:0] bomb4_coor;
    output reg [9:0] bomb5_coor;
    
    // OUTPUT to "VGA"
    output reg [4:0] vga_out_x;
    output reg [4:0] vga_out_y;
    output reg [2:0] vga_cell_type;
       
    // OUTPUT to "RAM"
    output reg [7:0] address_output;
    output reg [3:0] data_output;
    output reg storing_enable;
    
    /* RAM (Memmory) */
    localparam BITS_PER_CELL = 3'd4;
    localparam NUMBER_OF_ROWS = 4'd9;
    localparam NUMBER_OF_COLUMNS = 4'd11;
    
    
    // An always block that checks if fsm_mode == 3'b000.
    always @(posedge clk)
    begin
        // when it is not a reset and fsm_mode is "set".
        if((fsm_mode == 3'b000) & (resetn))
        begin
            storing_enable <= 1'b1;
            address_output <= (NUMBER_OF_COLUMNS * in_fsm_y) + in_fsm_x;
            data_output <= new_cell_type;
            
            // print the new_cell_typr iff plot_new_cell is 1'b1.
            if(plot_new_cell)
            begin
                vga_out_x <= in_fsm_x;
                vga_out_y <= in_fsm_y;
                vga_cell_type <= new_cell_type;
            end
            
            // Set ld_bomb_num to 10'b1111111111.
            case (ld_bomb_num)
                3'd0: bomb0_coor <= 10'b1111111111;
                3'd1: bomb1_coor <= 10'b1111111111;
                3'd2: bomb2_coor <= 10'b1111111111;
                3'd3: bomb3_coor <= 10'b1111111111;
                3'd4: bomb4_coor <= 10'b1111111111;
                3'd5: bomb5_coor <= 10'b1111111111;
            endcase
        end
    end
endmodule


/*****************************************************************************/
/* Reset the current map to the default map when there is an active low */
/* reset */
/*****************************************************************************/
module reset_map(clk,
                 resetn,
                 
                 // OUTPUT to "RAM"
                 address_output,
                 data_output,
                 storing_enable,
                 
                 // OUTPUT to "VGA"
                 vga_out_x,
                 vga_out_y,
                 vga_cell_type);
    
    input clk;
    input resetn;
           
    // OUTPUT to "VGA"
    output reg [4:0] vga_out_x;
    output reg [4:0] vga_out_y;
    output reg [2:0] vga_cell_type;
       
    // OUTPUT to "RAM"
    output reg [7:0] address_output;
    output reg [3:0] data_output;
    output reg storing_enable;
    
    /* RAM (Memmory) */
    localparam NUMBER_OF_ROWS = 4'd9;
    localparam NUMBER_OF_COLUMNS = 4'd11;
    localparam TOTAL_NUM_OF_CELLS = 10'd99;
    
    // PLAYER POSITION
    localparam DEFAULT_PLAYER_ADDRESS = NUMBER_OF_COLUMNS;
    localparam DEFAULT_PLAYER_X = 5'd1;
    localparam DEFAULT_PLAYER_Y = 5'd1;
    
    /* DIFFERENT TYPE OF CELL */
    localparam TILE = 3'b000;
    localparam PLAYER = 3'b001;
    localparam WALL = 3'b010;
    localparam BLOCK = 3'b011;
    localparam BOMB = 3'b100;
    
    reg [7:0] address_counter;
    wire address_counter_clear;
    reg [4:0] x_coor;
    wire x_coor_clear;
    reg [4:0] y_coor;
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
        begin
            storing_enable <= 1'b1;
            address_output <= address_counter;
            data_output <= WALL;
			
            // plot the new Cell
            vga_out_x <= x_coor;
            vga_out_y <= y_coor;
            vga_cell_type <= WALL;
            
            // move to the next address by setting the x_coor,
            // and address_counter.
            address_counter <= address_counter + 1'b1;
        end
        // If there is suppose to be a player, set that address and
        // cell to a player.
        else if(address_counter == DEFAULT_PLAYER_ADDRESS)
        begin
            storing_enable <= 1'b1;
            address_output <= address_counter;
            data_output <= PLAYER;
            
            // plot the new Cell
            vga_out_x <= x_coor;
            vga_out_y <= y_coor;
            vga_cell_type <= PLAYER;
            
            // move to the next address by setting the x_coor,
            // and address_counter.
            address_counter <= address_counter + 1'b1;
        end
        // Set the outer most WALL
        else if((x_coor == 5'd0) || (y_coor == 5'd0))
        begin
            // store the new Cell
            storing_enable <= 1'b1;
            address_output <= address_counter;
            data_output <= WALL;
            
            // plot the new Cell
            vga_out_x <= x_coor;
            vga_out_y <= y_coor;
            vga_cell_type <= WALL;
            
            // move to the next address by setting the x_coor,
            // and address_counter.
            address_counter <= address_counter + 1'b1;
        end
        // Set the BLOCK in the middle.
        else if(((x_coor > 5'd2) && (x_coor < (NUMBER_OF_COLUMNS - 3))) && ((y_coor > 5'd2) && (y_coor < (NUMBER_OF_ROWS - 3))))
        begin
            // store the new Cell
            storing_enable <= 1'b1;
            address_output <= address_counter;
            data_output <= BLOCK;
            
            // plot the new Cell
            vga_out_x <= x_coor;
            vga_out_y <= y_coor;
            vga_cell_type <= BLOCK;
            
            // move to the next address by setting the x_coor,
            // and address_counter.
            address_counter <= address_counter + 1'b1;
        end
        else
        begin
            // store the new Cell
            storing_enable <= 1'b1;
            address_output <= address_counter;
            data_output <= TILE;
            
            // plot the new Cell
            vga_out_x <= x_coor;
            vga_out_y <= y_coor;
            vga_cell_type <= TILE;
            
            // move to the next address by setting the x_coor,
            // and address_counter.
            address_counter <= address_counter + 1'b1;
        end
		
		if(!resetn)
		begin
			// Seting the counter back to default
			address_counter <= 2'd0;
         x_coor <= 5'd0;
         y_coor <= 5'd0;
		end
		else
		begin
			if(address_counter < TOTAL_NUM_OF_CELLS)
			begin
				if(x_coor == NUMBER_OF_COLUMNS)
				begin
					x_coor <= 5'd0;
					y_coor <= y_coor + 1'b1;
				end
				else
					x_coor <= x_coor + 1'b1;
			end
		 end
		 end
    
	/*
    // The counter for reset_counter, x_coor and y_coor.
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
        begin
            address_counter <= 2'd0;
            x_coor <= 5'd0;
            y_coor <= 5'd0;
        end
        else if(address_counter_clear)
            address_counter <= 2'd0;
        // When x_coor is set back to zero, we start in the
        // beginning of the next row => y_coor + 1.
        else if(x_coor_clear)
        begin
            x_coor <= 5'd0;
            y_coor <= y_coor + 1'b1;
        end
    end
    assign address_counter_clear = (address_counter == TOTAL_NUM_OF_CELLS);
    assign x_coor_clear = (x_coor == NUMBER_OF_COLUMNS);
	*/
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

module mil_25_counter(clock, clear_n, enable, out);
	input clock, clear_n, enable;
	reg[5:0] q;
	reg to_out;
	output out;
	
	always@(posedge clock or negedge clear_n)
	begin
		if(clear_n == 1'b0)
			q<= 0;
		else if(q == 5'd20)
			q <= q + 1'b1;
			to_out <= 0;
		end
	end
	assign out = to_out;
endmodule