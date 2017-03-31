// Part 2 skeleton

//module vga_test
//	(CLOCK_50,	//	On Board 50 MHz
//	// Your inputs and outputs here
//	KEY,
//	SW,
//	// The ports below are for the VGA output.  Do not change.
//	VGA_CLK,  //	VGA Clock
//	VGA_HS,   //	VGA H_SYNC
//	VGA_VS,	//	VGA V_SYNC
//	VGA_BLANK_N,//	VGA BLANK
//	VGA_SYNC_N,//	VGA SYNC
//	VGA_R,   	//	VGA Red[9:0]
//	VGA_G,	 //	VGA Green[9:0]
//	VGA_B,   	//	VGA Blue[9:0]
//	LEDR
//	);
//
//	input	   CLOCK_50;	//	50 MHz
//	input   [17:0]   SW;
//	input   [3:0]   KEY;
//
//	// Declare your inputs and oregutputs here
//	// Do not change the following outputs
//	output	VGA_CLK;  //	VGA Clock
//	output	VGA_HS;   //	VGA H_SYNC
//	output	VGA_VS;   //	VGA V_SYNC
//	output	VGA_BLANK_N; //	VGA BLANK
//	output	VGA_SYNC_N;  //	VGA SYNC
//	output	[9:0]	VGA_R;  //	VGA Red[9:0]
//	output	[9:0]	VGA_G;  //	VGA Green[9:0]
//	output	[9:0]	VGA_B;  //	VGA Blue[9:0]
//	
//	output [17:0] LEDR;
//	wire resetn;
//	assign resetn = KEY[0];
//	
//	// Create the colour, x, y and writeEn wires that are inputs to the controller.
//	wire [2:0] colour;
//	wire [6:0] x;
//	wire [6:0] y;
//	wire writeEn;
//
//	// Define the number of colours as well as the initial background
//	// image file (.MIF) for the controller.
//	vga_adapter VGA(
//			.resetn(resetn),
//			.clock(CLOCK_50),
//			.colour(colour),
//			.x(x),
//			.y(y),
//			.plot(writeEn),
//			/* Signals for the DAC to drive the monitor. */
//			.VGA_R(VGA_R),
//			.VGA_G(VGA_G),
//			.VGA_B(VGA_B),
//			.VGA_HS(VGA_HS),
//			.VGA_VS(VGA_VS),
//			.VGA_BLANK(VGA_BLANK_N),
//			.VGA_SYNC(VGA_SYNC_N),
//			.VGA_CLK(VGA_CLK));
//		defparam VGA.RESOLUTION = "160x120";
//		defparam VGA.MONOCHROME = "FALSE";
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//		defparam VGA.BACKGROUND_IMAGE = "black.mif";		
//	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
//	// for the VGA controller, in addition to any other functionality your design may require.
//	wire xloaden;
//	wire [3:0] countval;
//	datapath d0(
//			.resetn(resetn),
//			.clock(CLOCK_50),
//			.xload(xloaden),
//			.writeEn(writeEn),
//			.cin(SW[15:13]),
//			.xin(SW[5:0]),
//			.yin(SW[11:6]),
//			.cout(colour),
//			.xout(x),
//			.yout(y),
//			.countval(countval));
//    // Instansiate FSM control
//    // control c0(...);
//    control c0(
//			.resetn(resetn),
//			.clk(CLOCK_50),
//			.go(KEY[1]),
//			.xload(KEY[3]),
//			.writeEnPress(KEY[1]),
//			.countval(countval),
//			.xloaden(xloaden),
//			.writeEn(writeEn));
//		
//endmodule

module vgadatapath (resetn, clock, xload, cin, xin, yin, cout, xout, yout, writeEn, countval);
	input resetn, clock, xload;
	input writeEn;
	input [2:0] cin;
	input [5:0] xin, yin;
	output [2:0] cout;
	output [9:0] xout, yout;
	output [3:0] countval;

     // output registers for x and y, as well as a counter
	reg [5:0] xreg, yreg;
	//wire [9:0] xtmp, ytmp;
	reg [3:0] counter;

	// Default X to 2 times the entered coordinates
	//assign xtmp = xin+xin;
	//assign ytmp = yin+yin;

	always@(posedge clock) begin
	    if(!resetn) begin
		   xreg <= 5'b0;
		   yreg <= 5'b0;
		   counter <= 4'b0;
		end
	    else if(writeEn)begin
		   xreg <= xin + counter[1:0];
		   yreg <= yin + counter[3:2];
		   if(counter == 4'b1111) begin
			 counter <= 4'b0;
		    end
		    else begin
			 counter <= counter + 1'b1;
		    end
	    end
	end

	assign cout = cin;
	assign xout = xreg;
	assign yout = yreg;
	assign countval = counter;
endmodule

module vgacontrol (clk, resetn, go, xload, writeEnPress, countval, xloaden, writeEn);
	input clk, resetn, go, xload;
	input [3:0] countval;
	input writeEnPress;
	output reg xloaden, writeEn;

	reg [5:0] current_state, next_state;

	localparam S_LOAD		= 5'd0,
	           S_LOAD_WAIT		= 5'd1,
		   S_PLOT		= 5'd2;

	always@(*)
	begin: state_tablposedgee
		   case (current_state)
			  S_LOAD: next_state = go ? S_LOAD_WAIT: S_LOAD;
			  S_LOAD_WAIT: next_state = go ? S_LOAD_WAIT : S_PLOT;
			  S_PLOT: begin
				if (countval == 4'b0000 && !writeEnPress)
			     next_state = S_LOAD;
				else
			     next_state = S_PLOT;
			  end
		     default: next_state = S_LOAD;
		   endcase
	end

	// Output logic of datapath control signals
	always@(*)
	begin: enable_signals
	    xloaden = 1'b0;
	    writeEn = 1'b0;

	    case (current_state)
	        S_LOAD: begin
	            xloaden = 1'b1;
	        end
	        S_PLOT: begin
		    writeEn = 1'b1;
		end
	    endcase
	end

	// current_state registers
	always@(posedge clk)
	begin: state_FFS
	    if(!resetn)
		   current_state <= S_LOAD;
	    else
		   current_state <= next_state;
	end
endmodule


	

