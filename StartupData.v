`timescale 1ns/1ps

module StartupData (
	input wire clk,
	input wire nrst,
	input wire data_start,
	input wire startup_data,
	output wire startup_compl,
	output wire d
	);
	//DESCRIPTION//
	//This module starts the data protocol.
	//4 bits (1111) are send to the RX.
	//After that, there is a gap of 5 ms in which TX waits for a respons (1111) from the RX
	//If after 5 ms no respons is received, the duty cycle will be increased by 5% a
	//(1111) again will be send
	//
	//The receiving of the RX bits will be read from the 
	reg start_compl_reg = 0;
	reg d_reg = 0;

	always @(posedge startup_data)begin
		if(data_start && startup_data && ~start_compl_reg)begin
			d_reg <= 0;
			#2000000 d_reg = 1;

			#2000000 d_reg = 0;
			#2000000 d_reg = 1;

			#2000000 d_reg = 0;
			#2000000 d_reg = 1;
			
			#2000000 d_reg = 0;
			#2000000 d_reg = 1;

			#2000000 start_compl_reg <= 1;
		end
		else begin
			d_reg <= 0;
		end
	end
	assign startup_compl = start_compl_reg;
	assign d = d_reg;
endmodule

