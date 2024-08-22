`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/04 17:49:39
// Design Name: 
// Module Name: servo_controller
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


module servo_controller(
        input clk,          // 50M 主时钟
    input rst,          // 复位信号
    output uart_pin,    // 串口输出 
    input [11:0] angle_in,  // 角度输入，格式为4:4:4:4，每一个对应一个字符
    input [3:0] servo_id,   // 舵机ID
    input [3:0] move_seconds,   // 移动秒数
    input [3:0] move_hundreds_milliseconds,  // 移动百分之一秒数
    input go,                   // 开始信号
    output reg send_complete    // 发送完成信号
    );

wire  uart_busy;
reg [7:0] uart_data;
reg wr_control;
reg [2:0] byte_select;
wire [7:0] ascii_decoded;
reg ascii_cov_go;
wire ascii_cov_done;


// detect rising edge of go signal
reg go_last;
reg go_last_1;
always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        go_last <= 1'b0;
        go_last_1 <= 1'b0;
    end
    else
    begin
        go_last <= go;
        go_last_1 <= go_last;
    end
end
wire start = !go_last_1 & go_last || !go_last & go;


reg [5:0] send_counter;
reg write_start_latch;
reg [2:0] clock_skipper;
always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        send_counter <= 6'b0;
        wr_control <= 1'b0;
        send_complete <= 1'b1;
        byte_select <= 3'd3;
        ascii_cov_go <= 1'b0;
        write_start_latch <= 1'b0;
        clock_skipper <= 3'b0;
        uart_data <= 8'd0;
    end
    else if (start)
    begin
        send_counter <= 6'b0;
        send_complete <= 1'b0;
        byte_select <= 3'd3;
        ascii_cov_go <= 1'b1;
        write_start_latch <= 1'b1;
        wr_control <= 1'b0;
        clock_skipper <= 3'b0;
        uart_data <= 8'd0;
    end
    else
    begin 
        if (clock_skipper == 3'd4)
        begin
            clock_skipper <= 3'b0;
        if (write_start_latch && ascii_cov_done && !uart_busy)
        begin
            case (send_counter)
                6'd0: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd35; //#
                    send_counter <= send_counter + 1;
                end

                6'd2: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd0 + 8'd48 ;
                    send_counter <= send_counter + 1;
                end

                6'd4: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd0 + 8'd48 ;
                    send_counter <= send_counter + 1;
                end

                6'd6: begin
                    wr_control <= 1'b0;
                    uart_data <= servo_id + 8'd48;
                    send_counter <= send_counter + 1;
                end

                6'd8: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd80; //P
                    send_counter <= send_counter + 1;
                end

                6'd10: begin
                    wr_control <= 1'b0;
                    uart_data <= ascii_decoded;
                    send_counter <= send_counter + 1;
                end

                6'd11: begin
                    wr_control <= 1'b1;
                    byte_select <= 3'd2;
                    send_counter <= send_counter + 1;
                end

                6'd12: begin
                    wr_control <= 1'b0;
                    uart_data <= ascii_decoded;
                    send_counter <= send_counter + 1;
                end

                6'd13: begin
                    wr_control <= 1'b1;
                    byte_select <= 3'd1;
                    send_counter <= send_counter + 1;
                end

                6'd14: begin
                    wr_control <= 1'b0;
                    uart_data <= ascii_decoded;
                    send_counter <= send_counter + 1;
                end

                6'd15: begin
                    wr_control <= 1'b1;
                    byte_select <= 3'd0;
                    send_counter <= send_counter + 1;
                end


                6'd16: begin
                    wr_control <= 1'b0;
                    uart_data <= ascii_decoded;
                    send_counter <= send_counter + 1;
                end

                6'd18: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd84;   // T
                    send_counter <= send_counter + 1;
                end

                6'd20: begin
                    wr_control <= 1'b0;
                    uart_data <= move_seconds + 8'd48 ;
                    send_counter <= send_counter + 1;
                end

                6'd22: begin
                    wr_control <= 1'b0;
                    uart_data <= move_hundreds_milliseconds + 8'd48 ;
                    send_counter <= send_counter + 1;
                end

                6'd24: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd0 + 8'd48 ;
                    send_counter <= send_counter + 1;
                end

                6'd26: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd0 + 8'd48 ;   
                    send_counter <= send_counter + 1;
                end

                6'd28: begin
                    wr_control <= 1'b0;
                    uart_data <= 8'd33 ;   // !
                    send_counter <= send_counter + 1;
                end

                6'd30: begin
                    wr_control <= 1'b0;
                    send_complete <= 1'b1;
                    write_start_latch <= 1'b0;
                    byte_select <= 3'd3;
                    ascii_cov_go <= 1'b0;
                    clock_skipper <=0 ;
                end

                default: begin
                    wr_control <= 1'b1;
                    send_counter <= send_counter + 1;
                end
            endcase
        end
        end
        else
        begin
            clock_skipper <= clock_skipper + 1;
        end
    end  
end



bin2bcdascii ascii_cov(
    .rst(rst),
    .clk(clk),
    .binin(angle_in),
    .select(byte_select),
    .ascii(ascii_decoded),
    .go(ascii_cov_go),
    .done(ascii_cov_done)
);

UART_CONTROLLER_S uart_sender(
    .rst(rst),
    .clk(clk),
    .uart_pin(uart_pin),
    .WR(wr_control),
    .write_data(uart_data),
    .busy(uart_busy)
    );

endmodule


