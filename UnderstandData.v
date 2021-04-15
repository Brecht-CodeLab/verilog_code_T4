`timescale 1ps/1ps

module UnderstandData (
	input wire clk,
	input wire nrst,
    input wire swiptAlive,
    input wire data_start,
    input wire readDataIn,
    input wire din,
    output reg dataInReady,
    output reg [7:0] dataIn,
    output reg [7:0] sumChecker
);
    reg startReadOut;
    reg [19:0] counter;
    reg [35:0] dataStreamIn;

    initial begin
        startReadOut = 0;
        dataIn = 8'b0;
        counter = 20'h186A0;
        dataStreamIn = 36'h0;
        sumChecker = 8'h0;
    end
    

    always @(posedge clk) begin
        if(~nrst || ~swiptAlive || ~data_start || ~readDataIn)begin
            startReadOut <= 0;
            dataIn <= 36'b0;
            counter <= 20'h186A0;
            dataStreamIn <= 36'h0;
            sumChecker <= 8'h0;
        end
        else if(startReadOut && counter == 0)begin
            dataStreamIn <= {dataStreamIn << 1} + din;
            counter <= 20'h30D40;
            sumChecker <= sumChecker + din;
        end
        else if (startReadOut) begin
            counter <= counter - 1;
        end


       if((dataStreamIn[35:30] == 6'b101010) && (dataStreamIn[3:0] == 4'b0101))begin
            dataInReady <= 1;
            dataIn <= {dataStreamIn[20], dataStreamIn[18], dataStreamIn[16], dataStreamIn[14], dataStreamIn[12], dataStreamIn[10], dataStreamIn[8], dataStreamIn[6]};
        end
        else begin
            dataInReady <= 0;
        end
    end

    always @(posedge din or negedge readDataIn) begin
        if(~readDataIn)begin
            startReadOut <= 0;
        end
        else if (readDataIn && din) begin
            startReadOut <= 1;
        end
    end
endmodule