case (mode)
                00:begin
                    dataFromZybo <= 16'b1010101010101010;
                end
                01:begin
                    case (type)
                        00:begin
                            dataFromZybo <= SWIPT_P_TX;
                        end
                        01:begin
                            dataFromZybo <= SWIPT_DUTY;
                        end
                        10:begin
                            dataFromZybo <= SWIPT_FREQ;
                        end
                        11:begin
                            dataFromZybo <= SWIPT_ASCII;
                        end
                        default:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                    endcase
                end
                10:begin
                    case (type)
                        00:begin
                            dataFromZybo <= ANC_MAX_HEIGHT;
                        end
                        01:begin
                            dataFromZybo <= ANC_MIN_HEIGHT;
                        end
                        10:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                        11:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                        default:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                    endcase
                end
                11:begin
                    case (type)
                        00:begin
                            dataFromZybo <= COMMS_TRAJECT;
                        end
                        01:begin
                            dataFromZybo <= COMMS_QR_CODES;
                        end
                        10:begin
                            dataFromZybo <= COMMS_FLIGHT_TIME;
                        end
                        11:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                        default:begin
                            dataFromZybo <= 16'b1010101010101010;
                        end
                    endcase
                end
                default:begin
                    dataFromZybo <= 16'b1010101010101010;
                end
            endcase