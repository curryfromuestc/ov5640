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

// 串口读取模块
module UART_CONTROLLER_READ(
    input rst,          // 复位信号
    input clk,          // 50M 主时钟
    input uart_pin,     // 串口输入
    output reg [7:0] read_data,         // 读取数据
    output reg busy     // 忙信号
    );

parameter baud_rate = 921600;  // 波特率
parameter sys_clock_freq = 50000000;    // 系统时钟频率


reg uart_pin_buf;
always @(posedge clk)
begin
    uart_pin_buf <= uart_pin;    // 串口输入缓存
end

// 波特率生成
reg baud_rate_generate;
reg [4:0] baud_rate_counter;
always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                baud_rate_generate <= 1'b0;
                baud_rate_counter <= 5'b0;
            end
        else if (!busy) // if not busy, reset the baud rate
            begin
                baud_rate_generate <= 1'b0;
                baud_rate_counter <= 5'b0;
            end
        else if (baud_rate_counter == (sys_clock_freq/baud_rate)/2)
            begin
                baud_rate_generate <= ~baud_rate_generate;
                baud_rate_counter <= 5'b0;
            end
        else
            begin
                baud_rate_counter <= baud_rate_counter + 1;
            end
    end

// 波特率边沿检测
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

// 串口传输开始检测，检测到下降沿即为开始
reg last_read;
reg last_read_1;
always @(posedge clk or negedge rst )
    begin
        if (!rst )
            begin
                last_read <= 1'b1;
            end
        else
            begin
                last_read <= uart_pin_buf;
            end
    end

wire read_start = last_read & !uart_pin_buf;

reg [4:0] operator_counter;    // 操作计数器
reg read_start_latch;           // 读取开始锁存

always @(posedge clk or negedge rst)
    begin
        if (!rst)
            begin
                busy <= 1'b0;
                read_data <= 8'b0;
                operator_counter <= 5'b0;
                read_start_latch <= 1'b0;
            end
        else if (read_start && !read_start_latch)  // 读取开始
            begin
                read_start_latch <= 1'b1;
                busy <= 1'b1;
                operator_counter <= 5'b0;
            end
        else if (read_start_latch && busy)
            begin
            if ( baud_rate_edge)        // 波特率边沿检测为真后，变化数据
            begin
                    case (operator_counter)
                        5'd1: 
                            begin
                                read_data[0] <= uart_pin_buf;   // 读取数据
                                operator_counter <= operator_counter + 1;
                            end
                        5'd2: 
                            begin
                                read_data[1] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd3:
                            begin
                                read_data[2] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd4:
                            begin
                                read_data[3] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd5:
                            begin
                                read_data[4] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd6:
                            begin
                                read_data[5] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd7:
                            begin
                                read_data[6] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd8:
                            begin
                                read_data[7] <= uart_pin_buf;
                                operator_counter <= operator_counter + 1;
                            end
                        5'd9: // stop bit
                            begin
                                busy <= 1'b0;                       // 读取结束
                                read_start_latch <= 1'b0;
                            end
                       
                        default: begin operator_counter <= operator_counter + 1; end
                    endcase
            end
            end
    end

endmodule
