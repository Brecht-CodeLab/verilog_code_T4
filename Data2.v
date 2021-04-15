`timescale 1ns/1ps

module Data (
	input wire clk,
	input wire nrst,
	input wire swiptAlive,
	input wire data_start,
	input wire [11:0] ADC,
	input wire [11:0] mean_def,
	output read,
	output write,
	output dout,
	output reg l_rdy,
	output reg l_up_down,
	output getMeanCurrent,
	);
    
    wire din, dataInReady;
    wire [7:0] dataIn, sumChecker;

    reg write, read, getDataFromZybo, dout, readDataIn, getMeanCurrent;
    reg [1:0] mode, type;
    reg [7:0] dataFromZybo;
	reg [19:0] write_timer, blind;
    reg [19:0] write_timer_default = 20'h30D40;
	reg [23:0] read_timer; //2 500 000 clk cycli == 25ms wait time for answer
    reg [35:0] dataStream;

    `include "tasks.v"

    initial begin
        mode = 2'b00;
        type = 2'b00;
        write = 0;
        read = 0;
        dataStream = 36'b0;
        getMeanCurrent = 0;
        dout = 0;
        write_timer = 20'h30D40;
        read_timer = 24'h989680;
        blind = 20'hF4240;
        readDataIn = 0;
        GETDATAFROMZYBO(dataFromZybo);
    end


    always @(posedge clk) begin
        if(~nrst || ~swiptAlive || ~data_start)begin
            mode <= 2'b00;
            type <= 2'b00;
            getDataFromZybo <= 0;
            write <= 0;
            read <= 0;
            getMeanCurrent <= 0;
            dout <= 0;
        end
        else if(getDataFromZybo) begin
            getDataFromZybo <= 0;
            readDataIn <= 0;
            write <= 1;
            read <= 0;
            GETDATAFROMZYBO(dataFromZybo);
        end
        else if(write && write_timer == 0)begin
            datastream <= {6'b101010, mode, type, dataFromZybo, ^dataFromZybo, 4'b0101};
			if (stream_counter == 0)begin
                write <= 0;
                read <= 1;
                stream_counter <= 8'h23;
            end
            else begin
                stream_counter <= stream_counter - 1;
            end
            dout <= datastream[stream_counter];
            write_timer <= write_timer_default;
            getMeanCurrent <= 0;
        end
        else if(write)begin
            write_timer <= write_timer - 1;
            getMeanCurrent <= 0;
        end
        else if(read && read_timer == 0)begin
            readDataIn <= 0;
            case (mode)
                00:begin
                    case (type)
                        00:STARTUP();
                        01:
                        10:
                        11:POWEROPTIMIZATION();
                    endcase
                end
                01:
                10:
                11:
                default:
            endcase
        end
        else if(read)begin
            read_timer <= read_timer - 1;
            getMeanCurrent <= 0;
            

            if(dataInReady)begin
                readDataIn <= 0;
                read <= 0;
                getDataFromZybo <= 1;
                readTimer <= 
            end




            if(blind == 20'b0)begin
                readDataIn <= 1;
            end
            else begin
                blind <= blind - 1;
            end
		end      
    end


    ReadData2 inst_readdata2(
        .clk (clk),
		.nrst (nrst),
	    .swiptAlive (swiptAlive),
        .data_start (data_start),
        .readDataIn (readDataIn),
        .ADC (ADC),
        .mean_def (mean_def),
        .din (din)
    );

    UnderstandData inst_understanddata(
        .clk (clk),
        .nrst (nrst),
        .swiptAlive (swiptAlive),
        .data_start (data_start),
        .readDataIn (readDataIn),
        .din (din),
        .dataInReady (dataInReady),
        .dataIn (dataIn),
        .sumChecker (sumChecker)
    );


endmodule