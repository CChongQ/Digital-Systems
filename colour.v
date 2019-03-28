module colour
	(
input reset,clk,active,
output [2:0]image,
output [3:0]grid,
output [3:0]count
	);
	assign image = image_index;
	assign grif = grid_index;
 
 wire[2:0] image_index;	
 wire[3:0] grid_index;
 wire im_enable, draw_enable; 
 wire [10:0] count_image;
 assign plot_out_vga = 1'b1;
 wire[1:0]count_avacado,count_apple, count_coconut,count_kiwi,count_lemon,count_peach,
           count_pear,count_watermelon;
 wire allow_next,next;
		
		
		 
 lfsr m0(.clk(clk),.reset(reset),.allow_next(allow_next),.index_Q(image_index));	
 Image mo(
    .index(image_index),.clk(clk),.reset(reset),
	 .count_avacado(count_avacado),.count_apple(count_apple),.count_coconut(count_coconut),
		.count_kiwi(count_kiwi),.count_lemon(count_lemon),.count_peach(count_peach),.count_pear(count_pear),.count_watermelon(count_watermelon),
	.assign_sel(im_enable),.allow_next(allow_next));

wire [3:0]temp;
assign count = temp;
 grid m2(.clk(clk),.grid_index(grid_index), .count(temp),
       .next(next),.reset(reset),.enable_draw(draw_enable),.count_image(count_image),.next_image(allow_next));
 assignImage m3(.enable(draw_enable),.clk(clk),.index_grid(grid_index),.out_select(image_index),
                .x_out_image(x_out_vga),.y_out_image(y_out_vga),.out_Image(color_out_vga),
					 .count(count_image),.assign_sel(im_enable),.next(next));
 
		
endmodule

module lfsr(input clk,reset,input allow_next,output reg[2:0]index_Q);
 
 always@(posedge clk)
	 begin
	   if (reset==1)
		 index_Q <= 3'b1;
		else  
		  begin
		  if (allow_next == 1)
		    index_Q <= {index_Q[1:0],index_Q[1]^index_Q[2]};		
		  else index_Q <= index_Q;
        end		 
	 end              

endmodule 
 
  module Image(
   input [2:0]index,
	input clk,reset,allow_next,
	output reg [1:0]count_avacado,count_apple, count_coconut,count_kiwi,count_lemon,count_peach,
           count_pear,count_watermelon,
	output reg assign_sel);
			  
			  localparam[2:0] avacado = 3'd0,
                 apple = 3'd1,
					  coconut = 3'd2,
					  kiwi = 3'd3,
					  lemon = 3'd4,
					  peach = 3'd5,
					  pear = 3'd6,
					  watermelon = 3'd7;

always@(posedge clk)
    begin
	 if(reset)
	 begin
	   count_avacado = 2'b0;
		count_apple = 2'b0;
		count_coconut = 2'b0;
		count_kiwi = 2'b0;
		count_lemon = 2'b0;
		count_peach = 2'b0;
      count_pear= 2'b0;
		count_watermelon= 2'b0;	 
		assign_sel = 1'b1;
	 end
	 else
	 begin
	  if(index == avacado) 
	    begin
	      if (allow_next == 1'b1) count_avacado <= count_avacado +1;
			else count_avacado <= count_avacado;
			
			if(count_avacado <= 2) assign_sel = 1;
			else assign_sel = 1'b0;
		 end		  
	  
	  else if (index == apple)
	   begin
	   	if (allow_next == 1'b1)count_apple <= count_apple +1;
			else count_apple<= count_apple;
				
			if(count_apple <= 2) assign_sel = 1;
			else assign_sel = 1'b0;
		end
		
	  else if (index == coconut)
	   begin
	   	if (allow_next == 1'b1)count_coconut <= count_coconut+1;
			else count_coconut <= count_coconut;
			
			if(count_coconut <= 2) assign_sel = 1;
			else assign_sel = 1'b0;
		end
		
	  else if (index == kiwi )
	   begin
         if (allow_next == 1'b1)count_kiwi <= count_kiwi +1;
			else count_kiwi <= count_kiwi;
			
			if( count_kiwi <= 2) assign_sel = 1;
			else assign_sel = 1'b0;
		end
		
	  else if (index == lemon) 
	   begin
		   if (allow_next == 1'b1)count_lemon <= count_lemon+1;
			else count_lemon<= count_lemon;
			
			if(count_lemon <= 2) assign_sel = 1;
			else assign_sel = 1'b0;
		end
		
	  else if (index == peach) 
	    begin
		    if (allow_next == 1'b1)count_peach <= count_peach+1;
			else count_peach <= count_peach;
			
			 if(count_peach <= 2) assign_sel = 1;
			 else assign_sel = 1'b0;
		 end
		 
	  else if (index == pear) 
	    begin
		    if (allow_next == 1'b1)count_pear <= count_pear+1;
			else count_pear <= count_pear;
			
			 if(count_pear <= 2) assign_sel = 1;
			 else assign_sel = 1'b0;
		 end
		 
	  else if (index == watermelon)
	    begin
		    if (allow_next == 1'b1)count_watermelon<= count_watermelon+1;
			else count_watermelon<= count_watermelon;
			
			 if(count_watermelon <= 2) assign_sel = 1;
			 else assign_sel = 1'b0;       
		  end		 		 
	   end
	 
	 end	 
endmodule


module grid(
 input clk,reset,
 output reg [3:0]count,
 input next,
 output reg [10:0] count_image,
 output reg[3:0]grid_index,
 output reg enable_draw,output reg next_image);
 
 always@(posedge clk)
   begin
	  if(reset)
	     begin
	       enable_draw = 1'b0;
		    grid_index <= 4'b0;
			 next_image <= 1'b1;
		   end
	  else 
	    begin
	       if(grid_index <= 4'd15 )
	        begin
		       enable_draw = 1'b1;
		       if (next == 1)
				   begin
	             grid_index <= grid_index+1; 
					 next_image <= 1'b1;
					 count_image = 11'b0;
				   end
			    else
				   begin
					 count = count +1;
				    grid_index <= grid_index;
					 next_image <= 1'b0;
				   end
		     end
			else
	          begin		
				  grid_index <=4'd0; 
				 count = 4'b0;
				 end; 
	   end
   end
endmodule


module assignImage(
 input enable,clk,assign_sel,
 input[3:0] index_grid,
 input [2:0] out_select,
 output reg next,
	 output reg[8:0]x_out_image,
	 output reg [7:0]y_out_image,
	 output  reg [2:0] out_Image,
	 output reg [10:0] count);
	 
 reg[8:0]a;
 reg[7:0]b;
 wire[2:0]q_avocado,q_apple,q_watermelon,q_pear,q_cococut,q_kiwi,q_peach,q_lemon;
 
	 avocado one(.address(count),.clock(clk),.q(q_avocado));
	 apple two(.address(count),.clock(clk),.q(q_apple));
	 watermelon three(.address(count),.clock(clk),.q(q_watermelon));
	 pear four(.address(count),.clock(clk),.q(q_pear));
	 coconut five(.address(count),.clock(clk),.q(q_coconut));
	 kiwi six(.address(count),.clock(clk),.q(q_kiwi));
	 peach seven(.address(count),.clock(clk),.q(q_peach));
	 lemon eight(.address(count),.clock(clk),.q(q_lemon));
	 
	 localparam[2:0] avocado = 3'd0,
                 apple = 3'd1,
					  coconut = 3'd2,
					  kiwi = 3'd3,
					  lemon = 3'd4,
					  peach = 3'd5,
					  pear = 3'd6,
					  watermelon = 3'd7;
	 
	 always @(*)
			  begin
		      if(out_select == avocado)
			   begin	out_Image <= q_avocado; end
			   else if (out_select == apple) 
				 begin out_Image <= q_apple; end
			   else if (out_select == coconut)
			  begin	out_Image <= q_coconut; end
			   else if (out_select == kiwi) 
				begin out_Image <= kiwi; end
			   else if (out_select == lemon) 
				begin out_Image <= q_lemon; end
			   else if (out_select == peach)
			  begin 	out_Image <= q_peach; end
			   else if (out_select == pear) 
				begin out_Image <= q_pear; end
			   else if (out_select == watermelon)
			 begin	out_Image <= q_watermelon;		end	  			   
		     end	
 //(a,b)is the coordinate of the left-upper vertex of squre
 
  always @(posedge clk)
	     begin
		      if(enable == 1'b0)
				   begin
				      count <= 11'b0;
				   end
				else if (assign_sel == 1)
				   begin
					  if(count < 11'd1225)
					     begin
					     a = 9'd84 + (index_grid%4) *39;
	                 b = 8'd44 + (index_grid/4) *39;	 
	                 x_out_image = a + count / 35;
	                 y_out_image = b + count % 35;
						  count = count + 1;
						  next <= 1'b0;
						  end
						else
						 begin
						 count <= 11'b0;
						 next <= 1'b1;
						 end
					end
			end			
endmodule





