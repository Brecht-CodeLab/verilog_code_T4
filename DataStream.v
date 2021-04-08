`timescale 1ps/1ps

module DataStream (
	input wire clk,
	input wire nrst,
	input wire data_trans,
	input [31:0] datastream,
	output data_t_done,
	output wire d
	);

	reg [19:0] data_counter = 20'h186A0;
	reg [7:0] stream_counter = 8'h1F;
	reg data_done_reg = 0;
	reg data = 1'b1;

	always @(posedge clk)begin
		if(nrst && data_trans)begin
			if(data_counter == 0)begin
				if (stream_counter == 0)begin
					data_done_reg <= 1;
				end
				else begin
					stream_counter <= stream_counter - 1;
				end
				data <= datastream[stream_counter];
				data_counter <= 20'h186A0;
			end
			else begin
				data_counter <= data_counter - 1;
			end
		end
	end
	assign d = data;
	assign data_t_done = data_done_reg;
endmodule
