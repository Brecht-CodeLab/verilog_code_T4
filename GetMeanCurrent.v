`timescale 1ps/1ps

module GetMeanCurrent (
	input wire clk,
	input wire nrst,
	input wire swiptAlive,
	input wire measure,
	input wire [11:0] ADC,
	output reg [11:0] mean_curr
	);
	///Description
	//In this module, the mean current mesurement over x ms is given;
	//-----------------------
	reg [15:0] numberMeasurements = 0;
	reg [19:0] clk_cycles = 20'h9C40;
	reg [11:0] highest = 20'h0;
	reg [11:0] mean_curr_reg = 12'h0;
	
	always @(posedge clk)begin
		if(~nrst)begin
			numberMeasurements <= 0;
			clk_cycles <= 20'h9C40;
			highest <= 20'h0;
			mean_curr_reg <= 11'h0;
			mean_curr <= 0;
		end
		else if(measure)begin
			if(clk_cycles == 20'h0)begin
				clk_cycles <= 20'h9C40;
				highest <= 20'h0;
				numberMeasurements <= numberMeasurements + 1;
				mean_curr_reg <= ((numberMeasurements*mean_curr_reg)+(highest))/(numberMeasurements + 1);
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
			mean_curr <= mean_curr_reg;
		end
		else begin
			highest <= 11'h0;
			mean_curr_reg <= 11'h0;
		end
	end
endmodule

