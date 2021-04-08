`timescale 1ps/1ps

module CalcL (
	input wire clk,
	input wire nrst,
	input wire data_start,
	input wire data_trans,
	input wire data_rec,
	input wire [11:0] l_def,
	input wire d,
	output wire [11:0] l
	);

	reg [19:0] cnt_pos_d = 20'h0;
	reg [19:0] cnt_neg_d = 20'h0;
	reg [11:0] l_reg = 0;

	always @(posedge d)begin
		cnt_pos_d <= 20'h3000;
		cnt_neg_d <= 0;
	end

	always @(negedge d)begin
		cnt_pos_d <= 0;
		cnt_neg_d <= 20'h3000;
	end

	always @(posedge clk)begin
		if(data_start && ~data_rec && data_trans)begin
			if(cnt_pos_d == 20'h0 && d == 1)begin
				if((l_def + l_def/2) < 20'h1F4)begin
					l_reg <= l_def + l_def/2;
				end
				else if((l_def + l_def/3) < 20'h1F4)begin
					l_reg <= l_def + l_def/3;
				end
				else if((l_def + l_def/4) < 20'h1F4)begin
					l_reg <= l_def + l_def/4;
				end
				else if((l_def + l_def/5) < 20'h1F4)begin
					l_reg <= l_def + l_def/5;
				end
				else if((l_def + l_def/10) < 20'h1F4)begin
					l_reg <= l_def + l_def/10;
				end
				else begin
					l_reg <= 20'h1F4;
				end
			end
			else if(cnt_neg_d == 20'h0 && d == 0)begin
				if(20'h1F4 - l_def < l_def/5)begin
					l_reg <= 2*l_def - 20'h1F4;
				end
				else begin
					l_reg <= l_def/3; 
				end
			end
			else if(cnt_pos_d != 20'h0 && d == 1)begin
				cnt_pos_d <= cnt_pos_d - 1;
				l_reg <= 20'h1F4;
			end
			else if(cnt_neg_d != 20'h0 && d == 0)begin
				cnt_neg_d <= cnt_neg_d - 1;
				l_reg <= 20'h0;
			end
		end
		else if(data_start)begin
			l_reg <= l_def;
		end
	end
	assign l = l_reg;
endmodule

