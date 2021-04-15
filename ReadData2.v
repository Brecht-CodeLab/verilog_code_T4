`timescale 1ps/1ps

module ReadData2 (
	input wire clk,
	input wire nrst,
    input wire swiptAlive,
    input wire data_start,
    input wire readDataIn,
	input wire [11:0] ADC,
	input wire [11:0] mean_def,
    input reg din
	);

    reg [11:0] lowest;
    reg [19:0] clk_cycles;

    initial begin
        lowest = 0;
        clk_cycles = 20'h9C40;
    end

    always @(posedge clk)) begin
        if(~nrst || ~data_start || ~readDataIn)begin
			clk_cycles <= 20'h9C40;
			lowest <= 0;
		end
		else begin
			if(clk_cycles == 20'h0)begin
				lowest <= mean_def;
				clk_cycles <= 20'h9C40;
				
				if(lowest < (mean_def - mean_def/15))begin
					din <= 1;
				end
				else begin
					din <= 0;
				end
			end
			else begin
				clk_cycles <= clk_cycles - 1;
				if(ADC < 12'h800 && ADC > lowest)begin
					lowest <= ADC;
				end
				else if(ADC >= 12'h800 && 12'hFFF - ADC > lowest)begin
                	lowest <= 12'hFFF - ADC;
            	end
			end
		end
    end
endmodule