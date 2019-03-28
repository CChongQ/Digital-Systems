module proj
	(
		CLOCK_50,						//	On Board 50 MHz
		SW,
		KEY,
		HEX0,
		HEX1,
		LEDR,
		// Your inputs and outputs here
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	
	input			   CLOCK_50;				//	50 MHz
	// Declare your inputs and outputs here
	// Do not change the following outputs
	input    [9:0] SW;
	input    [3:0] KEY;
	output   [6:0] HEX0;
	output   [6:0] HEX1;
	output   [3:0] LEDR;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;   		//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	
	wire [8:0]x_out_vga;
	wire [7:0]y_out_vga;
	wire plot_out_vga;
	wire [2:0]color_out_vga;
	wire [3:0]state_hex;
	wire [3:0]current_index_hex;
	
	
	vga_adapter VGA(
			.resetn(~SW[9]),
			.clock(CLOCK_50),
			.colour(color_out_vga),
			.x(x_out_vga),
			.y(y_out_vga),
			.plot(plot_out_vga),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background.mif";
		
	control u0(
	           .clk(CLOCK_50),
	           .resetn(~SW[9]),
				  .left(~KEY[3]),
				  .right(~KEY[2]),
				  .select(~KEY[0]),
				  .start(~KEY[1]),
				  .x_out(x_out_vga),
				  .y_out(y_out_vga),
				  .plot_out(plot_out_vga),
				  .color_out(color_out_vga),
				  .state(state_hex),
				  .current_index_hex(current_index_hex),
				  .index_select1_grid_led(LEDR[3:0])
				 );	

		
endmodule		
		
module control(
    input clk,
    input resetn,
    input left,right, select,
	 input start,
	 
	 output reg [8:0]x_out,
	 output reg [7:0]y_out,
	 output reg plot_out,
	 output reg [2:0]color_out,	 
	 output [4:0] state,
	 output [3:0] current_index_hex,
	 output [2:0] index_image_hex,
	 output [3:0] index_select1_grid_led
	 );
	  	
	 reg [4:0] current_state, next_state;
	 reg plot, enable, selected1, enable_select_1, addSub, enable_rate; //whetherSelect;   //plot --- draw, enable --- move
	 wire [8:0]x_out_frame, x_out_image, x_out_black, x_out_chessboard;
	 wire [7:0]y_out_frame, y_out_image, y_out_black, y_out_chessboard;  
	 wire [10:0]frame_counter, image_counter, black_counter;
	 wire [16:0]chessboard_counter;
	 wire plot_out_frame, if_equal;
	 wire [2:0]color_out_chessboard, color_out_image, color_out_test;
	 assign state = current_state;
	 assign current_index_hex = current_grid;
	 assign index_image_hex = index_image;
	 assign index_select1_grid_led = index_select1_grid;
	 
	 
	reg [3:0]index_grid,printall_g_index;
	 wire [2:0]index_image;
	 wire [3:0]prev_grid, current_grid, index_select1_grid;
	 wire rate_50to3,rate_3s;
	  wire [4:0]count_printall;
	  wire [2:0]input_image;
	 
	 ratediv_50Mto1 nbjb(.clock(clk),.clear_b(resetn),.enable_rate(enable_rate),.flag(rate_50to3));
	 
	 ratediv_3to1 un2(.clock(rate_50to3),.clear_b(resetn),.enable_rate(enable_rate),.flag(rate_3s));
	 
	 draw_chessboard(.clk(clk),.plot(plot),.resetn(resetn),.x_out_chessboard(x_out_chessboard),
	                 .y_out_chessboard(y_out_chessboard),.color_out_chessboard(color_out_chessboard),
						  .chessboard_counter(chessboard_counter));
	 
	 grid_reg g0(.resetn(resetn),.clk(clk),.addSub(addSub),.enable(enable),
				    .prev_grid(prev_grid),.current_grid(current_grid));
	 draw_frame d0(.clk(clk),.plot(plot),.resetn(resetn),.index_grid(index_grid),
                  .x_out_frame(x_out_frame),.y_out_frame(y_out_frame),.plot_out_frame(plot_out_frame),
				      .frame_counter(frame_counter));			 
	 draw_image u1(.plot(plot),.clk(clk),.resetn(resetn),.index_grid(index_grid),
	               .index_image(index_image),
					   .x_out_image(x_out_image),.y_out_image(y_out_image),
	               .color_out_image(color_out_image),.image_counter(image_counter));
						
	 draw_black(.clk(clk),.plot(plot),.resetn(resetn),.index_grid(index_grid), 
	            .x_out_black(x_out_black),.y_out_black(y_out_black),
	            .black_counter(black_counter));					

	 reg_image_1 t2(.resetn(resetn),.clk(clk),
	             .enable_select_1(enable_select_1),.index_grid(current_grid),
					 .index_select1_grid(index_select1_grid));
					 
					 
	 equal t4(.index_select1_grid(index_select1_grid),.index_select2_grid(index_grid),
             .if_equal(if_equal)); 
	 colour lfsr(
	    .clk(clk),.reset(reset),.count(count_printall),.image(input_image),.grid(printall_g_index));

   image_table t1(.index_grid(printall_g_index),.image(input_image),
                   .index_image(index_image));
						 
			 
		
	 	
	 
    localparam  S_reset               = 5'd0,
					 S_memorize            = 5'd1,
					 S_draw_chessboard     = 5'd2,
					 S_draw_first          = 5'd3,
                S_wait_for_key        = 5'd4,
                S_left_wait           = 5'd5,
                S_left                = 5'd6,
					 S_right_wait          = 5'd7,
					 S_right               = 5'd8,
                S_erase_frame         = 5'd9,
					 S_rest_frame          = 5'd10,
					 S_draw_frame          = 5'd11,
					 S_select_wait         = 5'd12, 
					 S_select_which        = 5'd13,
                S_select_1            = 5'd14, //draw_image_1 
					 S_select_rest         = 5'd15,
					 S_flap_back_or_keep   = 5'd16,
					 S_draw_image_2        = 5'd17,
					 S_erase_image_1       = 5'd18,
					 S_printall            = 5'd19;




    //next state logic
	 always @(*)
    begin
            case (current_state)
    			    S_reset:   //0
					   begin
					      if(start)	
					           next_state = S_printall;
							else
							     next_state = S_reset;
						end
					S_printall:
					   begin
						  if(count_printall < 4'd15)
						   next_state = S_printall;
						  else 
						    next_state = S_memorize;					
						end					
					 S_memorize:
					   begin
						   if(rate_3s)
							     next_state = S_memorize;
							else
							     next_state = S_draw_chessboard;	  
				      end		
					 S_draw_chessboard:
					   begin 
							if(chessboard_counter < 11'd1849)      //1849 = 43 * 43
									next_state = S_draw_chessboard;	
							else
									next_state = S_draw_first;
						end
					 
   			    S_draw_first:  //1 
                  begin 
							if(frame_counter < 11'd1849)      //1849 = 43 * 43
									next_state = S_draw_first;	
							else
									next_state = S_wait_for_key;
						end
   			    S_wait_for_key: //2
					   begin
						   if(left)
							   next_state = S_left_wait;
						   else if(right)
							   next_state = S_right_wait;
							else if(select)
							   next_state = S_select_wait;	
							else
						      next_state = S_wait_for_key;		
						end
						
   			    S_left_wait: //3
					   begin
						   if(left)
							   next_state = S_left_wait;
							else
							   next_state = S_left;
						end
   			    S_left: //4
					   next_state = S_erase_frame;
						
   				 S_right_wait:  //5
					   begin
						   if(right)
							   next_state = S_right_wait;
							else
							   next_state = S_right;
						end
   				 S_right: //6
					   next_state = S_erase_frame;
				
   			    S_erase_frame:  //7
					   begin 
							if(frame_counter < 11'd1849)      //1849 = 43 * 43
									next_state = S_erase_frame;		
							else
									next_state = S_rest_frame;
						end
   				 S_rest_frame:  //8
					   next_state = S_draw_frame;
					 
   			    S_draw_frame:  //9
					   begin 
							if(frame_counter < 11'd1849)      //1849 = 43 * 43
									next_state = S_draw_frame;		
							else
									next_state = S_wait_for_key;
						end
    				 S_select_wait:   //10
					   begin
						   if(select)
							      next_state = S_select_wait;
							else
							      next_state = S_select_which;
						end
					 S_select_which:   //11
					   begin
						   if(selected1 == 0)
							    next_state = S_select_1;
							else
							    next_state = S_flap_back_or_keep;
						end
				    S_select_1:  //12
					   begin 
							if(image_counter < 11'd1225)      //35 * 35
									next_state = S_select_1;		
							else
									next_state = S_select_rest;
						end
					 S_select_rest:
					   next_state = S_wait_for_key;
						
				    S_flap_back_or_keep:  //13
					   begin
						   if(if_equal)
							   next_state = S_draw_image_2;
						   else
							   next_state = S_erase_image_1;
						end
				    S_draw_image_2:   //14
				      begin
						   if(image_counter < 11'd1225)      //35*35
									next_state = S_draw_image_2;		
							else
									next_state = S_wait_for_key;
						end
					 S_erase_image_1:  //15     //black the prev grid
					   begin
						   if(black_counter < 11'd1225)      //35*35
									next_state = S_erase_image_1;		
							else
									next_state = S_wait_for_key;
						end	
					
		
                default:     next_state = S_draw_first;
 
            endcase
    end
	 //output logic		
	 always @(*)
    begin

        case (current_state)	
		       S_reset: begin  //0
				     plot = 1'b0; //plot
					  enable = 1'b0;
					  selected1 = 1'b0;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  
					  enable_select_1 = 1'b0;
					  end  
				 S_printall:  //after print all grids, reset current_grid to 0
				      begin
				   plot = 1'b1;
					plot_out = 1'b1;
					enable = 1'b0;
					enable_rate = 1'b0;
					x_out = x_out_image;
					y_out = y_out_image;
					color_out = color_out_image;
					index_grid = printall_g_index;			 
				    end
				 S_memorize :
				   begin
					  enable_rate=1'b1;
					  plot = 1'b0; 
					  enable = 1'b0;
					  selected1 = 1'b0;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  
					  enable_select_1 = 1'b0;
					end
               S_draw_chessboard: begin   //14
				     plot = 1'b1;
				     plot_out = 1'b1;
					  enable = 1'b0;
					  enable_rate = 1'b0;
					  selected1 = 1'b0;
					  x_out = x_out_chessboard;
					  y_out = y_out_chessboard;
					  color_out = color_out_chessboard; 
					  index_grid = current_grid;
					  
					  enable_select_1 = 1'b0;
                 end	
		       S_draw_first: begin  //1
				     plot = 1'b1;
				     plot_out = plot_out_frame;
					  enable_rate = 1'b0;
					  enable = 1'b0;
					  selected1 = 1'b0;
	              x_out = x_out_frame;
	              y_out = y_out_frame;
	              color_out = 3'b001;   //blue
	              index_grid =	current_grid;
					  enable_select_1 = 1'b0;
					  
				     end
				 S_wait_for_key: begin  //2
				     plot = 1'b0;
					  enable = 1'b0;
					  plot_out = 1'b0;
					  enable_rate = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid; 
					  enable_select_1 = 1'b0;

					  
					  end
				 S_left_wait: begin  //3
	              plot = 1'b0;
					  enable = 1'b0;
					  plot_out = 1'b0;
					  enable_rate = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0; 
				     end	  
             S_left: begin   //4
				     plot = 1'b0;
					  enable = 1'b1;
					  addSub = 1'b0;
					  enable_rate = 1'b0;
                 plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;	
	              enable_select_1 = 1'b0;				  
                 end	
				 S_right_wait: begin   //5
	              plot = 1'b0;
					  enable = 1'b0;
					  plot_out = 1'b0;
					  enable_rate = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
				     end	  
             S_right: begin   //6
				     plot = 1'b0;
					  enable = 1'b1;
					  addSub = 1'b1;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
                 end				 
             S_erase_frame: begin    //7
				     plot = 1'b1;
				     plot_out = plot_out_frame;
					  enable = 1'b0;	
	              enable_rate = 1'b0;				  
					  x_out = x_out_frame;
					  y_out = y_out_frame;
					  color_out = 3'b111;   //white
					  index_grid = prev_grid;
					  enable_select_1 = 1'b0;
                 end		
				 S_rest_frame: begin   //8
		 		     plot = 1'b0;
					  enable = 1'b0;
					  plot_out = 1'b0;
					  enable_rate = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
					  end
		       S_draw_frame: begin   //9
				     plot = 1'b1;
				     plot_out = plot_out_frame;
					  enable = 1'b0;
					  enable_rate = 1'b0;
					  x_out = x_out_frame;
					  y_out = y_out_frame;
					  color_out = 3'b001;   //blue
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
                 end	
				 S_select_wait: begin   //10
				     plot = 1'b0;
					  enable = 1'b0;
					  addSub = 1'b0;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
					  
                 end	
				 S_select_which: begin   //11
				     plot = 1'b0;
					  enable = 1'b0;
					  addSub = 1'b0;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;

	              end		 
             S_select_1: begin   //12
				     plot = 1'b1;
				     plot_out = 1'b1;
					  enable = 1'b0;
					  enable_rate = 1'b0;
					  selected1 = 1'b1;
					  x_out = x_out_image;
					  y_out = y_out_image;
					  color_out = color_out_image;  
					  index_grid = current_grid;
					  
					  enable_select_1 = 1'b0;  //store

                 end	
				 S_select_rest: 
				   begin
				     plot = 1'b0;
				     plot_out = 1'b0;
					  enable_rate = 1'b0;
					  enable = 1'b0;
					  selected1 = 1'b1;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;  
					  
					  index_grid = current_grid;				  
					  enable_select_1 = 1'b1;
					  
					 end
		      		 
             S_flap_back_or_keep: begin   //13
				     plot = 1'b0;
					  enable = 1'b0;
					  addSub = 1'b0;
					  enable_rate = 1'b0;
					  plot_out = 1'b0;
					  x_out = 9'b0;
					  y_out = 8'b0;
					  color_out = 3'b0;
					  index_grid = current_grid;
					  enable_select_1 = 1'b0;
				     end
				 S_draw_image_2: begin   //14
				     plot = 1'b1;
				     plot_out = 1'b1;
					  enable = 1'b0;
					  enable_rate = 1'b0;
					  selected1 = 1'b0;
					  x_out = x_out_image;
					  y_out = y_out_image;
					  color_out = color_out_image; 
					  index_grid = current_grid;
					  
					  enable_select_1 = 1'b0;
                 end	  	 
				 S_erase_image_1: begin   //15
				     plot = 1'b1;
				     plot_out = 1'b1;
					  enable = 1'b0;
					  enable_rate = 1'b0;
					  x_out = x_out_black;
					  y_out = y_out_black;
					  color_out = 3'b0;    //black   
					  index_grid = index_select1_grid;
					  selected1 = 1'b0;
					  enable_select_1 = 1'b0;
			        end	
				 
				 default:     
					begin
					     plot = 1'b0;
						  plot_out = 1'b0;
						  enable = 1'b0;
						  enable_rate = 1'b0;
						  addSub = 1'b0;
						  index_grid = 1'b0;
						  enable_select_1 = 1'b0;
					end
		  endcase
	 end 
	 //next-state register
	 always@(posedge clk)
    begin 
        if(!resetn)
            current_state <= S_reset;
        else
            current_state <= next_state;
    end // state_FFS
	 
	 
endmodule


module draw_chessboard(
    input clk, plot, resetn, 
	 
	 output [8:0]x_out_chessboard,
	 output [7:0]y_out_chessboard,
	 output [2:0]color_out_chessboard,
	 output reg [16:0]chessboard_counter
	 );

	 assign x_out_chessboard = chessboard_counter / 320;
	 assign y_out_chessboard = chessboard_counter % 320;
	 
    chessboard	c1(
	              .address (chessboard_counter),
	              .clock (clk),
	              .q (color_out_chessboard)
                 );
					  
					  
    always @(posedge clk)
	     begin
		      if(!resetn) 
				    chessboard_counter <= 17'b0;
		      else if(plot == 1'b0)
				      chessboard_counter <= 17'b0;
				else if(plot == 1'b1)
				   begin
					  if(chessboard_counter < 17'd76800)
					     begin
						  chessboard_counter <= chessboard_counter + 1'b1;
						  end
					end		
        end
endmodule

		
		//to compute the index of current grid
module grid_reg(
                input resetn, clk, addSub, enable,
					 output reg [3:0] prev_grid, output reg [3:0]current_grid);
					 
	 always@(posedge clk, negedge resetn)
        begin
            if(!resetn)
				begin
					 prev_grid <= 4'b0;
                current_grid <= 4'b0;
			   end
            else if(enable)
				begin
					prev_grid <= current_grid;
				         if(addSub)
								begin
									if (current_grid < 4'd15)
										current_grid <= current_grid + 1'b1;
									else
										current_grid <= 4'b0;
								end
				         else
								begin
									if (current_grid > 4'b0)
										current_grid <= current_grid - 1'b1;
									else
										current_grid <= 4'd15;
								end		 
				end
        end 
endmodule					 
		

module draw_frame(
    input clk, plot, resetn,
	 input [3:0]index_grid, 
	 
	 output [8:0]x_out_frame,
	 output [7:0]y_out_frame,
	 output plot_out_frame,
	 output reg [10:0]frame_counter
	 );		
	 wire [8:0]m;
	 wire [7:0]n;
	 

	 //(index/4 is row, index%4 is colomn
    
	 assign m = 9'd80 + (index_grid%4)*39;
	 assign n = 8'd40 + (index_grid/4)*39;
	 assign x_out_frame = m + frame_counter / 43;
	 assign y_out_frame = n + frame_counter % 43;
	 
	 kuang frame1(
	             .address (frame_counter),
	             .clock (clk),
	             .q (plot_out_frame)
	             );

    always @(posedge clk)
	     begin
		      if(!resetn) 
				    frame_counter <= 11'b0;
		      else if(plot == 1'b0)
				      frame_counter <= 11'b0;
				else if(plot == 1'b1)
				   begin
					  if(frame_counter < 11'd1849)
					     begin
						  frame_counter <= frame_counter + 1'b1;
						  end
					end		
        end
endmodule

module draw_black(
    input clk, plot, resetn,
	 input [3:0]index_grid, 
	 
	 output reg[8:0]x_out_black,
	 output reg[7:0]y_out_black,
	 output reg [10:0]black_counter
	 );	
	 
	 reg [8:0]m;
	 reg [7:0]n;
	 

	 //(index/4 is row, index%4 is colomn
	 
	 always @(posedge clk)
	     begin
		      if(!resetn) 
				    black_counter <= 11'b0;
				else if(!plot)
				    black_counter <= 11'b0;
				else if(plot)
		          begin
				    if(black_counter < 11'd1225)
					   begin
						     m = 9'd84 + (index_grid/4) *39;
	                    n = 8'd44 + (index_grid%4) *39;
	                    x_out_black = m + black_counter / 35;
	                    y_out_black = n + black_counter % 35;
		   		     black_counter <= black_counter + 1;
						  end
					 end			           		 
	     end
	 
endmodule	 

module image_table(input [3:0]index_grid,input [2:0]image,
                   output reg [2:0]index_image);
						 	
	always @(*)
    begin	
                 case (index_grid)       
                       4'd0: index_image = image;
                       4'd1: index_image = image;
                       4'd2: index_image = image;
                       4'd3: index_image = image;
		                 4'd4: index_image = image;
		                 4'd5: index_image = image;
		                 4'd6: index_image = image;
		                 4'd7: index_image = image;
		                 4'd8: index_image = image;
		                 4'd9: index_image = image;
		                 4'd10: index_image = image;
		                 4'd11: index_image = image;
	               	  4'd12: index_image = image;
	                	  4'd13: index_image = image;
	                 	  4'd14: index_image = image;
	               	  4'd15: index_image = image;
		                 default: index_image = 3'd0;	 
		           endcase
	  
   end
endmodule



module equal(input [3:0]index_select1_grid, index_select2_grid,
             output reg if_equal);

 	 wire [2:0]index_image_1, index_image_2;
	 
    image_table(.index_grid(index_select1_grid),
                .index_image(index_image_1)
				    );
    image_table(.index_grid(index_select2_grid),
                .index_image(index_image_2)
				    );						 
	 always @(*)
        begin
           if(index_image_1 == index_image_2)
			       if_equal <= 1'b0;
			  else
			       if_equal <= 1'b1;  
        end		  										 					 
endmodule


module reg_image_1(input resetn, clk, enable_select_1,
                   input [3:0]index_grid, //current
					    output reg [3:0] index_select1_grid);
					  
	always@(posedge enable_select_1, negedge resetn)
        begin
            if(!resetn)
					    index_select1_grid <= 4'b0;
            else if(enable_select_1)
                  index_select1_grid <= index_grid;
        end

endmodule
	

					  
					  
module draw_image(
    input plot,clk, resetn,
    input[3:0] index_grid, 
    input[2:0] index_image,
	 output reg [8:0]x_out_image,
	 output reg [7:0]y_out_image,
	 output reg [2:0]color_out_image,
	 output reg [10:0]image_counter);
	 
 reg[8:0]a;
 reg[7:0]b;
 wire[2:0]q_kiwi,q_apple,q_watermelon,q_pear,q_coconut, q_lemon, q_peach, q_un;

    avocado one(.address(image_counter),.clock(clk),.q(q_un));
	 apple two(.address(image_counter),.clock(clk),.q(q_apple));
	 watermelon three(.address(image_counter),.clock(clk),.q(q_watermelon));
	 pear four(.address(image_counter),.clock(clk),.q(q_pear));
	 coconut five(.address(image_counter),.clock(clk),.q(q_coconut));
	 kiwi six(.address(image_counter),.clock(clk),.q(q_kiwi));
	 peach seven(.address(image_counter),.clock(clk),.q(q_peach));
	lemon eight(.address(image_counter),.clock(clk),.q(q_lemon));	 	 
 
 //(a,b)is the coordinate of the left-upper vertex of squre
	 
 
 always @(posedge clk)
	     begin
		      if(!resetn) 
				      image_counter <= 11'b0;
		      else if(plot == 1'b0)
				      image_counter <= 11'b0;
				else if(plot == 1'b1)
				   begin
					  if(image_counter < 11'd1225)
					     begin
			      a = 84 + (index_grid/4) *39;
       	      b = 44 + (index_grid%4) *39;
	            x_out_image = a + image_counter / 35;
	            y_out_image = b + image_counter % 35;
						  image_counter = image_counter + 1'b1;
						  end
					end
			end
		  
    always @(*)
    begin
        case (index_image)       
          3'd0: color_out_image <= q_watermelon;
		    3'd1: color_out_image <= q_apple;
		    3'd2: color_out_image <= q_lemon;
		    3'd3: color_out_image <= q_pear;
		    3'd4: color_out_image <= q_peach;
		    3'd5: color_out_image <= q_kiwi;
		    3'd6: color_out_image <= q_coconut;
		    3'd7: color_out_image <= q_un;		  
		  default: color_out_image <= q_kiwi;
		  endcase
	 end

endmodule

module ratediv_50Mto1(input clock, clear_b, enable_rate, output flag);

reg [25:0]tick;

	always@(posedge clock)
	begin
		if(!clear_b)
		begin
			tick <= 26'd50000000;
		end
		else if(enable_rate)
		begin
			if (tick == 26'b0)
				tick <= 26'd50000000;
			else 
				tick <= tick - 1'b1;
		end
	end
		assign flag = (tick == 26'b0) ? 1 : 0;
endmodule

module ratediv_3to1(input clock, clear_b, enable_rate, output flag);

reg [1:0]tick;

	always@(posedge clock)
	begin
		if(!clear_b)
		begin
			tick <= 2'd3;
		end
		else if(enable_rate)
		begin
			if (tick == 2'b0)
				tick <= 2'd3;
			else 
				tick <= tick - 1'b1;
		end
	end
		assign flag = (tick == 2'b0) ? 1 : 0;
endmodule
