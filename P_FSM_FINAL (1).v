module pcontrol(
		input [2:0] dir, tile_up, tile_right, tile_down, tile_left,
		input resetn, clk,
		output reg ld,
		output [2:0] out_dir);

	reg[4:0] current_state, next_state;
	//Tile identifiers
	localparam 	tile 	= 3'b000,
			player 	= 3'b001,
			wall 	= 3'b010,
			block 	= 3'b011;
	//Directions
	localparam	idle	= 3'b000,
			up 	= 3'b001,
			right 	= 3'b010,
			down 	= 3'b011,
			left	= 3'b100;


	//States
	localparam	p_load 	= 5'd0,
					p_idle 	= 5'd1,
               p_move	= 5'd2,
					p_write 	= 5'd3;


	// Direction checking modules for valid path
	reg valid;
	always@(*) begin
		valid <= 1'b0;
		if (dir == idle)
			valid <= 1'b0;
		else if (dir == up)
			valid <= tile_up == tile;
		else if (dir == right)
			valid <= tile_right ==tile;
		else if (dir == down)
			valid <= tile_down == tile;
		else
			valid <= tile_left == tile;
	end

	reg go;
	reg [4:0] q;
	always@(posedge clk)
	begin
		if(!resetn) begin
			q <= 1'b0;
			go <= 1'b0;
		end
		else if (q == 5'b11111) begin
			q <= 1'b0;
			go <= 1'b1;
		end
		else
			q <= q+1'b1;
			go <= 1'b0;
	end
	// next state table, only handles what states it will go to
	always@(*) begin
           case (current_state)
			p_load: begin
				next_state <= go ? p_idle: p_load;
			end
			p_idle: begin
				if(valid)
					next_state <= p_move;
				else
					next_state <= p_idle;							end
			p_move: begin
				next_state <= p_write;
			end
			default:	next_state <= p_load;
		endcase
	end
///////////////////TRYING TO WRITE AS IT READS//////////////////
    // Set datapath control signals and assign values
    always @(*)
    begin: enable_signals
        // By default make all our signals 

		ld <= 1'b0;

		case (current_state)
			// For movement states, change coordinates here
			p_move: begin
				if(valid) begin
				   ld <= 1'b1;
				end
			end
			// default: // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
		endcase
	end // enable_signals
	assign out_dir = dir;

	// change states
	always@(posedge clk)
    	begin: state_FFS
        	if(!resetn) begin
            current_state <= p_load;
			end
        	else
            current_state <= next_state;
    	end // state_FFS

endmodule
