`timescale 1ps/1ps

module DutyAdjust (
	input wire clk,
	input wire nrst,
	input wire data_start,
	input wire data_trans,
	input wire data_rec,
	input wire l_rdy,
	input wire l_up_down,
	input wire d,
	input wire [11:0] l,
	input wire [11:0] l_def,
	output reg [11:0] l_adj
	);

	reg [19:0] cnt_pos_d = 20'h0;
	reg [19:0] cnt_neg_d = 20'h0;

	always @(posedge d)begin
		cnt_pos_d <= 20'h3000;
		cnt_neg_d <= 0;
	end

	always @(negedge d)begin
		cnt_pos_d <= 0;
		cnt_neg_d <= 20'h3000;
	end

	always @(posedge clk)begin
		if(~nrst)begin
			l_adj <= l;
		end
		else if(l_rdy && l_up_down)begin
			if((l + l/10) < 12'h1F4)begin
				l_adj <= l + (l/10);
			end
			else begin
				l_adj <= 12'h1F4;
			end
		end
		else if(l_rdy && ~l_up_down)begin
			l_adj <= l - (l/10);
		end
		else if(data_start && ~data_rec && data_trans)begin
			if(cnt_pos_d == 20'h0 && d == 1)begin
				if((l_def + l_def/2) < 20'h1F4)begin
					l_adj <= l_def + l_def/2;
				end
				else if((l_def + l_def/3) < 20'h1F4)begin
					l_adj <= l_def + l_def/3;
				end
				else if((l_def + l_def/4) < 20'h1F4)begin
					l_adj <= l_def + l_def/4;
				end
				else if((l_def + l_def/5) < 20'h1F4)begin
					l_adj <= l_def + l_def/5;
				end
				else if((l_def + l_def/10) < 20'h1F4)begin
					l_adj <= l_def + l_def/10;
				end
				else begin
					l_adj <= 20'h1F4;
				end
			end
			else if(cnt_neg_d == 20'h0 && d == 0)begin
				if(20'h1F4 - l_def < l_def/5)begin
					l_adj <= 2*l_def - 20'h1F4;
				end
				else begin
					l_adj <= l_def/3; 
				end
			end
			else if(cnt_pos_d != 20'h0 && d == 1)begin
				cnt_pos_d <= cnt_pos_d - 1;
				l_adj <= 20'h1F4;
			end
			else if(cnt_neg_d != 20'h0 && d == 0)begin
				cnt_neg_d <= cnt_neg_d - 1;
				l_adj <= 20'h0;
			end
		end
		else if(data_start)begin
			l_adj <= l_def;
		end
		else if(l_adj > 0)begin
			l_adj <= l_adj;
		end
		else begin
			l_adj <= l;
		end
	end
endmodule
