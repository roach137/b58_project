module Datapath(
input ld, clk, resetn,
input [2:0] dir, ram_val,
output reg [2:0]up_r, left_r, right_r, down_r, out_val,
output reg [3:0]vga_x, vga_y, 
output reg plot);

	reg [4:0] p_x, p_y;
	reg [2:0] what_ram_says;
	reg [4:0] current_state, next_state;
	reg [1:0] ram_c;
	reg [2:0] vga_c;
	
	localparam 		ram_limit = 2'd1,
				vga_limit = 2'd1;

	localparam 	tile 	= 3'b000,
				player 	= 3'b001,
				wall 	= 3'b010,
				block 	= 3'b011,
				bomb	= 3'b100;
	//Directions
	localparam	idle	= 3'b000,
				up 		= 3'b001,
				right 	= 3'b010,
				down 	= 3'b011,
				left	= 3'b100,
				plant 	= 3'b101;

	localparam 	load 				= 5'd0,
				get_next_pos		= 5'd1,
				get_left 		= 5'd2,
				wait_left 		= 5'd3,
				add_left		= 5'd4,
				process_left 		= 5'd5,
				get_right 		= 5'd6,
				wait_right 		= 5'd7,
				add_right		= 5'd8,
				process_right 		= 5'd8,
				get_up 			= 5'd9,
				wait_up 		= 5'd10,
				add_up			= 5'd11,
				process_up 		= 5'd12,
				get_down 		= 5'd13,
				wait_down 		= 5'd14,
				add_down		= 5'd15,
				process_down 		= 5'd16,
				wait_vga		= 5'd17,
				add_vga			= 5'd18,
				send_dat 		= 5'd19,
				reset_state 		= 5'd20;
				
	//state table
	always@(*)
	begin
		if(!resetn) next_state <= reset_state;
		
		else
		begin
			case(current_state)
				load: if(ld)next_state <= get_left;
				get_left: next_state <= wait_left;
				wait_left: begin
					if(ram_c < ram_limit) next_state <= add_left;
					else next_state <= process_left;
				end
				add_left: next_state <= wait_left;
				process_left: next_state <= get_right;
				get_right: next_state <= wait_right;
				wait_right: begin
					if(ram_c < ram_limit) next_state <= add_right;
					else next_state <= process_right;
				end
				add_right: next_state <= wait_right;
				process_right: next_state <= get_up;
				get_up: next_state <= wait_up;
				wait_up: begin
					if(ram_c < ram_limit) next_state <= add_up;
					else next_state <= process_up;
				end
				add_up: next_state <= wait_up;
				process_up: next_state <= get_down;
				get_down: next_state <= wait_down;
				wait_down: begin
					if(ram_c < ram_limit) next_state <= add_down;
					else next_state <= process_down;
				end
				add_down: next_state <= wait_down;
				process_down: next_state <= wait_vga;
				wait_vga: begin 
					if(vga_c < vga_limit)next_state <= add_vga;
					else next_state <= send_dat;
				end
				send_dat: next_state <= load;
				reset_state: next_state <= load;
				default: next_state <= load;
			endcase;
		end
	end
	
	//operations at state
	always@(posedge clk or negedge resetn)
	begin
		//set default values
		plot <= 0;
		
		case(current_state)
			//send tile to prev position for gavvy
			load: begin
				//sets current working x and y as player position
				vga_x <= p_x;
				vga_y <= p_y;
				end
			get_next_pos:begin
				plot <= 1'b1;
				out_val <= tile;
				if(dir == up) p_y <= p_y + 1;
				else if(dir == down) p_y <= p_y - 1;
				else if(dir == right) p_x <= p_x + 1;
				else if(dir == left) p_x <= p_x - 1;
			end
			
			get_left: vga_x <= p_x - 1;
			wait_left: what_ram_says <= ram_val;
			add_left: ram_c <= ram_c + 1;
			process_left: begin
				left_r <= what_ram_says;
				ram_c <= 0;
			end
			get_right: vga_x <= p_x + 1;
			wait_right: what_ram_says <= ram_val;
			add_right: ram_c <= ram_c + 1;
			process_right: begin 
			right_r <= what_ram_says; 
			ram_c <= 0;
			end
				
			get_up: begin
				vga_x <= p_x;
				vga_y <= p_y + 1;
			end
			wait_up: what_ram_says <= ram_val;
			add_up: ram_c <= ram_c + 1;
			process_up: begin
				up_r <= what_ram_says; 
				ram_c <= 0;
			end
			
			get_down: vga_y <= p_y - 1;
			wait_down: what_ram_says <= ram_val;
			add_down: ram_c <= ram_c + 1;
			process_down: begin 
				down_r <= what_ram_says; 
				ram_c <= 0;
			end
			add_vga: vga_c <= vga_c + 1;
			// send dat
			send_dat: begin
				vga_x <= p_x;
				vga_y <= p_y;
				out_val <= player;
				vga_c <= 0;
				plot <= 1'b1;
			end
			reset_state: begin
				p_x <= 5'd1;
				p_y <= 5'd1;
				vga_c <= 0;
				ram_c <= 0;
				what_ram_says <= 0;
			end
		endcase
	end
	
	// iterate state
	always@(posedge clk)
    begin: state_FFS
           current_state <= next_state;
    end // state_FFS
endmodule

module make_default(
input clk, resetn,
output wren_o,
output reg [3:0]ram_x, ram_y,
output [2:0]ram_val,
output [3:0]c_s,
output [4:0]c);

	reg[3:0] x, y;
	reg[3:0] current_state, next_state;
	reg[4:0] counter;
	reg wren;
	assign wren_o = wren;
	assign c_s = current_state;
	assign c = counter;
	
	//get block type from module
	wire [2:0] val_out;
	block_type b0(ram_x, ram_y, val_out);
	assign ram_val = val_out;
	
	// decide limits here
	localparam 	max_x = 4'd11,
				max_y = 4'd9,
				vga_wait = 5'd16;
	
	// state table values
	localparam  plot	 	= 4'd0,
				increment_x = 4'd1,
				check_vga	= 4'd2,
				add_vga 	= 4'd3,
				check_y		= 4'd4,
				increment_y = 4'd5,
				end_state 	= 4'd7,
				reset_s = 4'd8;
	
	//goes through state table
	always@(posedge clk or negedge resetn)
	begin
		if(!resetn) next_state <= reset_s;
		else
		begin
			case(current_state)
				// sends to increment if not done row, else checks for y
				plot: begin
					if(x < max_x) next_state <= increment_x;
					else next_state <= check_y;
				end
				// increments x then checks if vga done waiting
				increment_x: next_state <= check_vga;
				// if vga < wait time then we add vga o/w back to plot
				check_vga: begin
					if(counter < vga_wait) next_state <= add_vga;
					else next_state <= plot;
				end
				// adds 1 to counter
				add_vga: next_state <= check_vga;
				// if less than max_y increments y o/w sends to end state as done making arena
				check_y: begin
					if(y < max_y) next_state <= increment_y;
					else next_state <= end_state;
				end
				// loops back to self
				end_state: next_state <= end_state;
				reset_s: next_state <= plot;
				default: next_state <= plot;
			endcase
		end
	end
	
	// performs actions for state
	always@(*)
	begin
		// default do not write to RAM
		wren <= 0;
		case(current_state)
			// want to write to RAM and plot values
			plot: begin
				// set vga counter back to 0
				counter <= 0;
				// sets output x and y
				ram_x <= x;
				ram_y <= y;
				// tells ram to writ;
			end
				wren <= 1
			increment_x: x <= x + 1;
			add_vga: counter <= counter + 1;
			increment_y: y <= y + 1;
			//sets everything back to default
			end_state: begin
				x <= 4'd0;
				y <= 4'd0;
				ram_x <= 4'd0;
				ram_y <= 4'd0;
				counter <= 5'd0;
			end
			reset_s:
			begin
				x <= 4'b0000;
				y <= 4'b0000;
				ram_x <= 4'b0000;
				ram_y <= 4'b0000;
				counter <= 5'b00000;
				wren <= 1'd0;
			end
			
		endcase
	end
	
	// iterate state
    always@(posedge clk)
    begin: state_FFs
			current_state <= next_state;
    end // state_FFS

endmodule

module block_type(
input[3:0] x, y,
output reg [2:0] val);

	// list of possible block values
	localparam 	tile 	= 3'b000,
				player 	= 3'b001,
				wall 	= 3'b010,
				block 	= 3'b011,
				bomb	= 3'b100;
	
		localparam 	max_x = 4'd11,
					max_y = 4'd9;
	
	// condition list
	always@(*)
	begin
		// player spawn so sets as player
		if(x == 1 && y == 1) val <= player;
		// walls border
		else if(x == 0 || (y == 0 || (x == max_x || y == max_y))) val <= wall;
		// tiles to walk on
		else if( (x % 2) == 1 || (y % 2) == 1) val <= tile;
		// walls in intruding player
		else val <= wall;
	end

endmodule
