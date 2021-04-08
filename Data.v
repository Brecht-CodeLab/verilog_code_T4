`timescale 1ns/1ps

module Data (
	input wire clk,
	input wire nrst,
	input wire swiptAlive,
	input wire data_start,
	input wire [11:0] ADC,
	input wire [11:0] mean_def,
	output wire read,
	output wire write,
	output wire dout,
	output wire l_rdy,
	output wire l_up_down,
	output wire get_mean_curr
	);

//*********************************************************//
//Description:
//	This module regulates all the data transfer from/to the drone to/from the ground.
//	Communication from the drone to the ground are 20 bits (40 bit manchester code) and
//	is a standard for EAGLE SWIPT2: 000   00   00   1100100101   000
//									strt  stng type	data		 end
//	strt: start sequence
//	stng: setting = what we are sending:
//		00: startup (answer required)
//		01: power optimization
//		11: data
//		10: a question (answer required)
//	type: only for data and questions
//		00: power
//		01: efficienty
//		11: current DC
//		10: voltage DC
//	data: rough data (voltage, current, power, efficientie), fixed point
//	end: end sequence
//	
//	Manchester coding:
//		1 --> 01
//		0 --> 10
//*********************************************************//
//Inputs:
//	clk: clock
//	nrst: low active reset
//	swiptAlive: given parameter for the TA's for the activation of the drone (switch 
//				on RC is turned on)
//	data_start: if freq opt is finished and stable link is set --> high
//	ADC: live ADC input from link
//	mean_def: 

//Outputs:
//	dout: the data wire that goes to CalcL to adjust the duty cycle
//Variables:
//	setting: 2 bit number in bitstream
//*********************************************************//
	
	reg [1:0] setting = 2'b00;
	reg l_up_down_reg = 1;
	reg l_rdy_reg = 0;
	reg get_mean_curr_reg = 0;
	reg l_set = 0;
	
	//READ
	wire din;
	reg din_reg = 0;
	reg read_reg = 0;
	reg [19:0] clk_cycles = 20'h9C40;
	reg [11:0] highest = 0;
	reg [19:0] deaf = 20'h7A120;
	reg [23:0] read_timer_default = 24'h2625A0;
	reg [23:0] read_timer = 24'h2625A0; //2 500 000 clk cycli == 25ms wait time for answer
	reg answer_00 = 0;
	reg [1:0] answer_01 = 0;
	
	//WRITE
	reg write_reg = 1;
	reg [19:0] write_timer_default = 20'h186A0;
	reg [19:0] write_timer = 20'h186A0;
	reg [7:0] stream_counter = 8'h27;
	reg [39:0] datastream = 40'b10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_10_10_10;

	//OUPUT
	reg dout_reg = 0;

	always @(posedge clk)begin
	//WRITE & ACTIONS
		if(~nrst || ~data_start)begin
			setting <= 2'b00;
			dout_reg <= 0;
			datastream <= 40'b10_10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_10_10_10;
			stream_counter <= 8'h27;
			l_up_down_reg <= 1;
			l_rdy_reg <= 0;
			get_mean_curr_reg <= 0;
			read_timer <= read_timer_default;
			write_timer <= write_timer_default;
		end

		//STARTUP
		else if(setting == 2'b00)begin
			if(write && write_timer == 0)begin
				if (stream_counter == 0)begin
					write_reg <= 0;
					read_reg <= 1;
					stream_counter <= 8'h27;
				end
				else begin
					stream_counter <= stream_counter - 1;
				end
				dout_reg <= datastream[stream_counter];
				write_timer <= write_timer_default;
				get_mean_curr_reg <= 0;
			end
			else if(write)begin
				write_timer <= write_timer - 1;
				get_mean_curr_reg <= 0;
			end
			else if(read && read_timer == 0)begin
				if(answer_00 == 1'b1)begin
					setting <= 2'b01;
					write_reg <= 1;
					read_reg <= 0;
					read_timer <= read_timer_default;
					get_mean_curr_reg <= 0;
					datastream <= 40'b10_10_10_10_01_01_01_01_01_01_01_01_01_01_01_01_01_10_10_10;
				end
				else begin
					if(~l_set)begin
						l_set <= 1;
						l_rdy_reg <= 1;
						l_up_down_reg <= 1;
						get_mean_curr_reg <= 0;
					end
					else begin
						//l up
						l_rdy_reg <= 0;
						l_up_down_reg <= 1;
						get_mean_curr_reg <= 1;
						#20000000;
						write_reg <= 1;
						read_reg <= 0;
						l_set <= 0;
						read_timer <= read_timer_default;
					end
				end
			end
			else if(read)begin
				read_timer <= read_timer - 1;
				get_mean_curr_reg <= 0;
			end
		end

		//POWER OPTIMIZATION
		else if(setting == 2'b01)begin
			if(write && write_timer == 0)begin
				if (stream_counter == 0)begin
					write_reg <= 0;
					read_reg <= 1;
					stream_counter <= 8'h27;
				end
				else begin
					stream_counter <= stream_counter - 1;
				end
				dout_reg <= datastream[stream_counter];
				write_timer <= write_timer_default;
				get_mean_curr_reg <= 0;
			end
			else if(write)begin
				write_timer <= write_timer - 1;
				get_mean_curr_reg <= 0;
			end
			else if(read && read_timer == 0)begin
				if(answer_01 > 2'b01)begin
					setting <= 2'b11;
					write_reg <= 1;
					read_reg <= 0;
					read_timer <= read_timer_default;
					get_mean_curr_reg <= 0;
					datastream <= 40'b10_10_10_01_01_01_10_01_01_10_01_10_01_10_01_10_01_10_10_10;
				end
				else if(answer_01 == 2'b01)begin
					//l down
					if(~l_set)begin
						l_set <= 1;
						l_rdy_reg <= 1;
						l_up_down_reg <= 0;
						get_mean_curr_reg <= 0;
					end
					else begin
						l_rdy_reg <= 0;
						l_up_down_reg <= 0;
						get_mean_curr_reg <= 1;
						#20000000;
						write_reg <= 1;
						read_reg <= 0;
						l_set <= 0;
						read_timer <= read_timer_default;
					end
				end
				else begin
					//l up
					if(~l_set)begin
						l_set <= 1;
						l_rdy_reg <= 1;
						l_up_down_reg <= 1;
						get_mean_curr_reg <= 0;
					end
					else begin
						l_rdy_reg <= 0;
						l_up_down_reg <= 1;
						get_mean_curr_reg <= 1;
						#20000000;
						write_reg <= 1;
						read_reg <= 0;
						l_set <= 0;
						read_timer <= read_timer_default;
					end
				end
			end
			else if(read)begin
				read_timer <= read_timer - 1;
				get_mean_curr_reg <= 0;
			end
		end

		//DATA TRANSFER
		else if(setting == 2'b11)begin
			if(write && write_timer == 0)begin
				if (stream_counter == 0)begin
					//Temporary algorithm
					stream_counter <= 8'h27;
					//Final algorithm
					//write_reg <= 0;
					//read_reg <= 1;
				end
				else begin
					stream_counter <= stream_counter - 1;
				end
				dout_reg <= datastream[stream_counter];
				write_timer <= 20'h30D40;
				get_mean_curr_reg <= 0;
			end
			else if(write)begin
				write_timer <= write_timer - 1;
				get_mean_curr_reg <= 0;
			end
		end

		//ASK QUESTION
		else if(setting == 2'b10)begin

		end



		//READ DATA
		if(~nrst || ~data_start || ~read || get_mean_curr)begin
			clk_cycles <= 20'h9C40;
			highest <= 0;
			din_reg <= 0;
			deaf <= 20'h7A120;
		end
		else if(deaf == 0)begin
			if(clk_cycles == 20'h0)begin
				highest <= mean_def;
				clk_cycles <= 20'h9C40;
				
				if(highest > (mean_def + mean_def/20))begin
					din_reg <= 1;
				end
				else begin
					din_reg <= 0;
				end
			end
			else begin
				clk_cycles <= clk_cycles - 1;
				if(ADC < 12'h800 && ADC > highest)begin
					highest <= ADC;
				end
				else if(ADC >= 12'h800 && 12'hFFF - ADC > highest)begin
                	highest <= 12'hFFF - ADC;
            	end
			end
		end
		else begin
			deaf <= deaf - 1;
		end


		if(l_rdy_reg == 1'b1)begin
			l_rdy_reg <= 1'b0;
		end
	end


	//ANSWER DETECTION
	always @(posedge din)begin
		if(~nrst || ~data_start || ~read || get_mean_curr)begin
			answer_00 <= 1'b0;
			answer_01 <= 2'b0;
		end
		else if(setting == 2'b00)begin
			answer_00 <= 1'b1;
		end
		else if(setting == 2'b01)begin
			answer_01 <= answer_01 + 1;
		end
	end

	assign l_rdy = l_rdy_reg;
	assign l_up_down = l_up_down_reg;
	assign dout = dout_reg;
	assign din = din_reg;
	assign write = write_reg;
	assign read = read_reg;
	assign get_mean_curr = get_mean_curr_reg;
endmodule
