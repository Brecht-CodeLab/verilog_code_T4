`timescale 1ps/1ps

task GETDATAFROMZYBO(output [15:0] dataFromZybo);
    begin
        case (mode)
            00:dataFromZybo <= 16'b1010101010101010;
            01:begin
                case (type)
                    00:dataFromZybo <= SWIPT_P_TX;
                    01:dataFromZybo <= SWIPT_DUTY;
                    10:dataFromZybo <= SWIPT_FREQ;
                    11:dataFromZybo <= SWIPT_ASCII;
                    default:dataFromZybo <= 16'b1010101010101010;
                endcase
            end
            10:begin
                case (type)
                    00:dataFromZybo <= ANC_MAX_HEIGHT;
                    01:dataFromZybo <= ANC_MIN_HEIGHT;
                    10:dataFromZybo <= 16'b1010101010101010;
                    11:dataFromZybo <= 16'b1010101010101010;
                    default:dataFromZybo <= 16'b1010101010101010;
                endcase
            end
            11:begin
                case (type)
                    00:dataFromZybo <= COMMS_TRAJECT;
                    01:dataFromZybo <= COMMS_QR_CODES;
                    10:dataFromZybo <= COMMS_FLIGHT_TIME;
                    11:dataFromZybo <= 16'b1010101010101010;
                    default:dataFromZybo <= 16'b1010101010101010;
                endcase
            end
            default:dataFromZybo <= 16'b1010101010101010;
        endcase
    end
endtask

task STARTUP();
    begin
        if(sumChecker == 7'b0)begin
            //Higher duty
            l_rdy <= 1;
            l_up_down <= 1;
            getMeanCurrent <= 0;
        end
        else if(sumChecker == 7'b1)begin
            //Done
            mode <= 2'b00;
            type <= 2'b11;//Go to poweroptimization
            getDataFromZybo <= 1;
            read <= 0;
        end
        else begin
            //Problem
        end
    end
endtask

task POWEROPTIMIZATION();
    begin //POWER OPTIMIZATION
        if(sumChecker == 7'b0)begin
            //Higher duty
            l_rdy <= 1;
            l_up_down <= 1;
            getMeanCurrent <= 1;
        end
        else if (sumChecker == 7'b1) begin
            //Lower duty
            l_rdy <= 1;
            l_up_down <= 0;
            getMeanCurrent <= 1;
        end
        else if (sumChecker == 7'b11) begin
            //Done
            mode <= 2'b00;
            type <= 2'b11; //Power optimization
            getDataFromZybo <= 1;
        end
        else begin
            //There has been a problem
        end
    end
endtask

