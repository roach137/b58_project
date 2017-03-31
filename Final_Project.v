module Final_Project(SW, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, CLOCK_50);
	input [17:0]SW;
	input [3:0]KEY;
	output [17:0]LEDR;
	input CLOCK_50;
	output [6:0]HEX0;
	output [6:0]HEX1;
	output [6:0]HEX2;
	output [6:0]HEX3;
	output [6:0]HEX4;
	output [6:0]HEX5;
	
	wire ld, plot, def_w, wren, wren1, wren2, wren3, wren4, wren5, clk;
	wire [2:0] co_dir_out, ram_val_out_w, ram_val_in_w, def_ram_in, ram_in;
	wire [2:0] up_w, left_w, right_w, down_w;
	wire [3:0] x_out, y_out, def_x, def_y, vga_x, vga_y;
	wire [7:0] ram_pos;
	
	mux2to1 m0(plot, def_w, def_w, wren);
	mux2to1_3bit m1(ram_val_in_w, def_ram_in, def_w, ram_in);
	mux2to1_8bit m2({x_out,y_out}, {def_x,def_y}, def_w, ram_pos);
	mux2to1_4bit m3(x_out, def_x, def_w, vga_x);
	mux2to1_4bit m4(y_out, def_y, def_w, vga_y);
	
	assign wren1 = wren;
	assign wren2 = wren;
	assign wren3 = wren;
	//assign wren4 = wren;
	assign wren5 = wren;
	assign clk = SW[0];
	
	ram256x4 (
					ram_pos,
					clk,
					ram_in,
					wren,
					ram_val_out_w);
					
	make_default md0(
					clk, SW[17],
					def_w, //check this guy is connected
					def_x, def_y,
					def_ram_in, LEDR[17 : 14], LEDR[13:9]);

	
	Datapath d0(ld, clk, SW[17],
					co_dir_out, ram_val_out_w,
					up_w, left_w, right_w, down_w, ram_val_in_w, 
					x_out, y_out, 
					plot);
					
	pcontrol c0(
					SW[2:0], up_w, right_w, down_w, left_w,
					SW[17], clk,
					ld,
					co_dir_out);
	
	wire xloaden;
					
	vga_datapath d1(SW[17], clk, xloaden, ram_in, vga_x, vga_y, cout, xout, yout, wren4, countval);
	//resetn, clock, xload, cin, xin, yin, cout, xout, yout, writeEn, countval

	vga_control c1(clk, SW[17], wren5, wren1, wren2, countval, xloaden, wren4);
		//clk, resetn, go, xload, writeEnPress, countval, xloaden, writeEn
			//output reg xloaden, writeEn;
			
	assign LEDR[0] = def_w;
	assign LEDR[4:1] = def_x;
	assign LEDR[8:5] = def_y;
	//assign LEDR[11:9] = def_ram_in;
					
endmodule


module mux2to1(x, y, s, m);
    input x; //selected when s is 0
    input y; //selected when s is 1
    input s; //select signal
    output m; //output
  
    assign m = s & y | ~s & x;
    // ORmodule vga_datapath (resetn, clock, xload, cin, xin, yin, cout, xout, yout, writeEn, countval);

    // assign m = s ? y : x;

endmodule

module mux2to1_3bit(x, y, s, m);
    input [2:0]x; //selected when s is 0
    input [2:0]y; //selected when s is 1
    input s; //select signal
    output [2:0]m; //output
  
    assign m = (s && y) || (~s && x);
    // OR
    // assign m = s ? y : x;

endmodule

module mux2to1_4bit(x, y, s, m);
    input [3:0]x; //selected when s is 0
    input [3:0]y; //selected when s is 1
    input s; //select signal
    output [3:0]m; //output
  
    assign m = (s && y) || (~s && x);
    // OR
    // assign m = s ? y : x;

endmodule

module mux2to1_8bit(x, y, s, m);
    input [7:0]x; //selected when s is 0
    input [7:0]y; //selected when s is 1
    input s; //select signal
    output [7:0]m; //output
  
    assign m = (s && y) || (~s && x);
    // OR
    // assign m = s ? y : x;

endmodule

module vga_datapath (resetn, clock, xload, cin, xin, yin, cout, xout, yout, writeEn, countval);
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

module vga_control (clk, resetn, go, xload, writeEnPress, countval, xloaden, writeEn);
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

