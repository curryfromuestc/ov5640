`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/03 19:42:06
// Design Name: 
// Module Name: UART_CONTROLLER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_CONTROLLER_WRITE(
    input rst,
    input clk,
    output uart_pin,
    input WR, // 1 is write DO NOT change it while busy
    input [7:0] write_data,
    output reg busy
    );

parameter baud_rate = 921600;
parameter sys_clock_freq = 50000000;




reg baud_rate_generate;
reg [8:0] baud_rate_counter;
always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                baud_rate_generate <= 1'b0;
                baud_rate_counter <= 9'b0;
            end
        else if (!busy) // if not busy, reset the baud rate
            begin
                baud_rate_generate <= 1'b0;
                baud_rate_counter <= 9'b0;
            end
        else if (baud_rate_counter == (sys_clock_freq/baud_rate)/2)
            begin
                baud_rate_generate <= ~baud_rate_generate;
                baud_rate_counter <= 9'b0;
            end
        else
            begin
                baud_rate_counter <= baud_rate_counter + 1;
            end
    end


reg data_line_write_buf;

assign  uart_pin = WR ? data_line_write_buf:1'b1;


reg last_baud_clock;
always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                last_baud_clock <= 1'b0;
            end
        else
            begin
                last_baud_clock <= baud_rate_generate;
            end
    end
wire baud_rate_edge = !last_baud_clock & baud_rate_generate ;

//generate write_start signal
reg WR_last;
reg WR_last_1;
always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                WR_last <= 1'b0;
                WR_last_1 <= 1'b0;
            end
        else 
            begin
                WR_last <= WR;
                WR_last_1 <= WR_last;
            end
    end
wire write_start = !WR_last_1 & WR_last ;


reg [3:0] operator_counter;


always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                busy <= 1'b0;
                data_line_write_buf <= 1'b1;
                operator_counter <= 4'b0;
            end
        else if (write_start)
            begin
                busy <= 1'b1;
                operator_counter <= 4'b0;
            end
        
        else if (WR && busy)
            begin
            if (baud_rate_edge)
            begin
                case(operator_counter)
                    4'd0: 
                        begin
                            data_line_write_buf <= 1'b0;
                            operator_counter <= operator_counter + 1;
                        end
                    4'd1: 
                        begin
                            data_line_write_buf <= write_data[0];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd2: 
                        begin
                            data_line_write_buf <= write_data[1];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd3: 
                        begin
                            data_line_write_buf <= write_data[2];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd4: 
                        begin
                            data_line_write_buf <= write_data[3];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd5: 
                        begin
                            data_line_write_buf <= write_data[4];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd6: 
                        begin
                            data_line_write_buf <= write_data[5];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd7: 
                        begin
                            data_line_write_buf <= write_data[6];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd8: 
                        begin
                            data_line_write_buf <= write_data[7];
                            operator_counter <= operator_counter + 1;
                        end
                    4'd9: 
                        begin
                            data_line_write_buf <= 1'b1;
                            operator_counter <= operator_counter + 1;
                        end
                    4'd10:
                        begin
                            data_line_write_buf <= 1'b1;
                            busy <= 1'b0;
                        end
                    default: data_line_write_buf <= 1'b1;
                endcase
            end
    end

        
    end

endmodule
