`timescale 1ps/1ps

module ReadData (
	input wire clk,
	input wire nrst,
	input wire data_rec,
	input wire [11:0] ADC,
	input wire [11:0] mean_def,
	output wire read
	);

	reg [19:0] clk_cycles = 20'h9C40;
	reg read_reg = 0;
	reg [11:0] highest = 0;
	

	always @(posedge clk)begin
		if(data_rec)begin
			if(clk_cycles == 20'h0)begin
				highest <= mean_def;
				clk_cycles <= 20'h9C40;
				
				if(highest > (mean_def + mean_def/10))begin
					read_reg <= 1;
				end
				else if (highest < (mean_def + mean_def/30))begin
					read_reg <= 0;
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
			highest <= mean_def;
		end
	end
	assign read = read_reg;
endmodule
