`timescale 1ps/1ps


module toplevel ();
//------BEGIN SETUP------//
	//--GIVEN INPUTS AND OUTPUTS (for now they are not perfectly right)--//
	reg clk = 2'b1;
	reg nrst = 1'b0;
	reg swiptONHeartbeat = 1'b1;
	wire [11:0] ADC_in;
	reg [31:0] bitstream = 32'b01_01_01_01_10_10_10_10_10_01_01_10_10_01_10_01;
							 //1  1  1  1  0  0  0  0  0  1  1  0  0  1  0  1

	wire SWIPT_OUT0;
	wire SWIPT_OUT1;
	wire SWIPT_OUT2;
	wire SWIPT_OUT3;
	//--GIVEN INPUTS AND OUTPUTS (for now they are not perfectly right)--//

	//--DEFINITION OF CLK, NRST AND SWIPTONHEARTBEAT--//
	always #10000 clk = ~clk;
	always #900000 swiptONHeartbeat <= ~swiptONHeartbeat;

	// Reset
	initial begin
		#1000000000 nrst = 1'b1;
	end	
	//--DEFINITION OF CLK, NRST AND SWIPTONHEARTBEAT--//

//------END SETUP------//

//------BEGIN PARAM & VAR------//
	///Parameters for algorithms given by TA's///
	wire swiptAlive;
	
	///ADC_in
	wire ADC0;
	wire ADC1;
	wire ADC2;
	wire ADC3;
	wire ADC4;
	wire ADC5;
	wire ADC6;
	wire ADC7;
	wire ADC8;
	wire ADC9;
	wire ADC10;
	wire ADC11;

	///Frequency Default
	reg [19:0] freq = 20'h9C40; //Default freq is 38 100 Hz
	wire [19:0] freq_new;

	wire l_rdy_freq;
	wire l_up_down_freq;

    ///Freq Varibles
    wire freq_optimum; //Default no optimum
	wire freq_rdy; //Default 0
    wire freq_set_up_down; //Default up in nrst

    ///Power Variables
    wire power_optimum = 1; //Default no power optimum
	wire [19:0] mean_curr;
	reg measure = 0;

	///Data Send
    wire data_go;
	wire data_start;

	wire write;
	wire data_start_led;


	wire d;
	reg [11:0] l = 12'h0FA;
	//wire [11:0] l_data;
	wire [11:0] l_adj;
	reg [11:0] l_def = 0;
	wire [19:0] best_freq;

	wire l_rdy_data;
	wire l_up_down_data;
	wire get_mean_curr_data;

	reg l_rdy;
	reg l_up_down;

	///Data Receive
	wire read;

//------END PARAM & VAR------//	
	always @(posedge data_start)begin
		l_def <= l;
	end
	always @(posedge clk)begin
		if(data_start)begin
			measure <= get_mean_curr_data;
		end
		else if(data_go && ~data_start)begin
			measure <= 1;
		end
		else begin
			measure <= 0;
		end



		if(data_start && l_rdy_data)begin
			if(l_up_down && (l_def + l_def/10) < 12'h1F4)begin 
				l_def <= l_def + l_def/10;
			end
			else if(l_up_down && (l_def + l_def/10) > 12'h1F4)begin
				l_def <= 12'h1F4;
			end
			else if(~l_up_down)begin
				l_def <= l_def - l_def/10;
			end
		end
		else begin
			l_rdy <= l_rdy_freq;
			l_up_down <= l_up_down_freq;
		end
	end

	
//------BEGIN MODULES------//
	//set swipt alive
	Heartbeat inst_heartbeat (
			.clk (clk),
			.nrst (nrst),
			.swiptONHeartbeat (swiptONHeartbeat),
			.swipt (swiptAlive)
			);
	
	Freq inst_freq (
			.clk (clk),
            .nrst (nrst),
			.data_start (data_start),
            .ADC_in (ADC_in),
			.freq (freq),
            .freq_ready (freq_rdy),
            .freq_set_up_down (freq_set_up_down),
            .freq_opt (freq_optimum),
			.best_freq (best_freq),
			.l_rdy (l_rdy_freq),
			.l_up_down (l_up_down_freq)
			);

	SwiptOut inst_swiptout (
			.clk (clk),
			.nrst (nrst),
			.freq (freq),
			.l (l),
			.SWIPT_OUT0 (SWIPT_OUT0),
			.SWIPT_OUT1 (SWIPT_OUT1),
			.SWIPT_OUT2 (SWIPT_OUT2),
			.SWIPT_OUT3 (SWIPT_OUT3)
			);

	Optimization inst_optimization (
			.clk (clk),
			.nrst (nrst),
			.swiptAlive (swiptAlive),
			.freq (freq),
			.freq_optimum (freq_optimum),
			.freq_rdy (freq_rdy),
			.freq_set_up_down (freq_set_up_down),
			.power_optimum (power_optimum),
			.best_freq (best_freq),
			.data_go (data_go),
			.data_start (data_start),
			.freq_new (freq_new),
			.data_start_led (data_start_led)
			);

	//CalcL inst_calcl (
			//.clk (clk),
			//.nrst (nrst),
			//.data_start (data_start),
			//.data_trans (write),
			//.data_rec (read),
			//.l_def (l_def),
			//.d (d),
			//.l (l_data)
			//);

	DutyAdjust inst_dutyadjust(
			.clk (clk),
			.nrst (nrst),
			.data_start (data_start),
			.data_trans (write),
			.data_rec (read),
			.l_rdy (l_rdy),
			.l_up_down (l_up_down),
			.d (d),
			.l (l),
			.l_def (l_def),
			.l_adj (l_adj)
			);

	GetMeanCurrent inst_getmeancurr(
			.clk (clk),
			.nrst (nrst),
			.swiptAlive (swiptAlive),
			.measure (measure),
			.ADC (ADC_in),
			.mean_curr (mean_curr)
			);

	Data inst_data(
			.clk (clk),
			.nrst (nrst),
			.swiptAlive (swiptAlive),
			.data_start (data_start),
			.ADC (ADC_in),
			.mean_def (mean_curr),
			.read (read),
			.write (write),
			.dout (d),
			.l_rdy (l_rdy_data),
			.l_up_down (l_up_down_data),
			.get_mean_curr (get_mean_curr_data)
			);
	
	ANALOG_NETWORK inst_ANALOG_NETWORK (
			.SWIPT_OUT0	(SWIPT_OUT0),
			.SWIPT_OUT1	(SWIPT_OUT1),
			.SWIPT_OUT2 (SWIPT_OUT2),
			.SWIPT_OUT3 (SWIPT_OUT3),
			.ACOUT0 (ADC11),
			.ACOUT1 (ADC10),
			.ACOUT2 (ADC9),
			.ACOUT3 (ADC8),
			.ACOUT4 (ADC7),
			.ACOUT5 (ADC6),
			.ACOUT6 (ADC5),
			.ACOUT7 (ADC4),
			.ACOUT8 (ADC3),
			.ACOUT9 (ADC2),
			.ACOUT10 (ADC1),
			.ACOUT11 (ADC0)
			);



//------END MODULES------//

//------BEGIN ASSIGNMENT------//
	always @(negedge clk)begin
		freq <= freq_new;
	end
	always @(posedge clk)begin
		l <= l_adj;
	end
	
	//assign d = d_reg;

	assign ADC_in[11] = ADC11;
	assign ADC_in[10] = ADC10;
	assign ADC_in[9] = ADC9;
	assign ADC_in[8] = ADC8;
	assign ADC_in[7] = ADC7;
	assign ADC_in[6] = ADC6;
	assign ADC_in[5] = ADC5;
	assign ADC_in[4] = ADC4;
	assign ADC_in[3] = ADC3;
	assign ADC_in[2] = ADC2;
	assign ADC_in[1] = ADC1;
	assign ADC_in[0] = ADC0;

//------END ASSIGNMENT------//
endmodule
