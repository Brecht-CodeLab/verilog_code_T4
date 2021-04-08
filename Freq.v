`timescale 1ps/1ps

module Freq (
	input wire clk,
	input wire nrst,
	input wire data_start,
	input wire [11:0] ADC_in,
	input wire [19:0] freq,
	output reg freq_ready,
	output reg freq_set_up_down,
	output reg freq_opt,
	output reg [19:0] best_freq,
	output reg l_rdy,
	output reg l_up_down
	);

	reg [11:0] highest_so_far;
	reg [11:0] lowest_so_far;
	reg lets_go = 1'b0;
	reg [3:0] counter_freq_opt = 0;

	//For this algorithm, we will calculate the maximum current
    reg [11:0] old_highest = 12'h000;
    reg [11:0] new_highest = 12'h000;
    
    //clk = 50MHz; Samp = 1MHz; Power ~= 40khz --> #clk_cycl/period_power ~= 50*25 = 1250 clk_cycli/power_cyclus
    //If we choose around 4 power_cycli to messure --> clk_counter = 4*1250 = 5000
    reg [19:0] clk_cycles = 20'h1E848; //Every highest messurement is done over 5000 clk_cycles

    reg [19:0] threshold = 20'hA0; //Treshhold is default 5/2048 = 0,244 % - Can be modified (2048 = 11bit = 12'h7FF)
    
    always @(posedge clk)begin

        if(~nrst)begin
			//Reset
            freq_ready <= 0;
            freq_set_up_down <= 1; //Default is up
            freq_opt <= 0; //Default is no optimum
            clk_cycles <= 20'h1E848;

            old_highest <= 12'h000;
            new_highest <= 12'h000;
        end
		else if(data_start)begin
			freq_ready <= 0;
            clk_cycles <= 20'h1E848;

            old_highest <= 12'h000;
            new_highest <= 12'h000;
		end
        else if(clk_cycles == 0)begin
            //If the counter is set zero --> compare old_highest to new_highest
            //Compare highest value of previous messurement to the new messurement 
            //duration: 5000 clk_cycles each
            old_highest <= new_highest;
			new_highest <= 12'h000;
            clk_cycles <= 20'h1E848;

            if(old_highest < new_highest)begin
				$display("Right direction");
                //Right direction
                freq_set_up_down <= freq_set_up_down;
                freq_ready <= 1;
            end
            else if(old_highest > new_highest)begin
                //Wrong direction
                freq_set_up_down <= ~freq_set_up_down;
                freq_ready <= 1;
            end

            else begin
                //Optimum
                //We found an optimum --> end freq optimization algorithm
				freq_set_up_down <= freq_set_up_down;
                freq_ready <= 1;
            end
        end

        else if(clk_cycles < 20'hF424)begin
            //Compare the new current value to the existing highest one
            //new_highest is always a value between 0 and 7FF = 11bit
			freq_ready <= 0;
			//freq_set_up_down <= freq_set_up_down;
			clk_cycles <= clk_cycles - 1;

            if(ADC_in < 12'h800 && ADC_in > new_highest)begin
                new_highest <= ADC_in; //ADC_in is value between 0 and 7FF and is larger than new_highest
            end
            else if(ADC_in >= 12'h800 && 12'hFFF - ADC_in > new_highest)begin
                new_highest <= 12'hFFF - ADC_in;
            end
			else begin
				new_highest <= new_highest;
			end
        end
		else begin
			freq_ready <= 0;
			clk_cycles <= clk_cycles - 1;
		end
	
		if(freq_ready && ~lets_go)begin
			highest_so_far <= old_highest;
			lowest_so_far <= old_highest;
			lets_go <= 1;
		end

		if(counter_freq_opt == 4 && freq_ready)begin
			counter_freq_opt <= counter_freq_opt + 1;
			if(highest_so_far > 12'h6CB)begin
				freq_opt <= 0;
				l_rdy <= 1;
				l_up_down <= 0;
			end
			else if((highest_so_far - lowest_so_far) < threshold && old_highest > 12'h400)begin
				freq_opt <= 1;
				threshold <= 12'h140;
				l_rdy <= 0;
				l_up_down <= 1;
			end
			else if((highest_so_far - lowest_so_far) < threshold)begin
				l_rdy <= 1;
				l_up_down <= 1;
				freq_opt <= 0;
			end
			else begin
				freq_opt <= 0;
				threshold <= 12'hA0;
				l_rdy <= 0;
				l_up_down <= 1;
			end
			counter_freq_opt <= 0;
			highest_so_far <= old_highest;
			lowest_so_far <= old_highest;
		end
		else if(freq_ready)begin
			l_rdy <= 0;
			counter_freq_opt <= counter_freq_opt + 1;
			if (old_highest > highest_so_far)begin
				highest_so_far <= old_highest;
				best_freq <= freq;
			end
			else if(old_highest < lowest_so_far)begin
				lowest_so_far <= old_highest;
			end
		end
		else begin
			l_rdy <= 0;
		end		
	end

endmodule
