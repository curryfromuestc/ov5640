module uart_watcher(
    input         clk     ,//50M 主时钟
    input           rst_n   ,   //复位信号

    input           en      ,//使能信号
    input   [15:0]  din     ,// 像素信号输入
    output    reg      sdram_rd_req ,// sdram读请求
    input           sdram_read_ack,//   sdram读应答

    output          uart_pin        // 串口输出
);


// 在读取应答信号有效时，将数据缓存到uart_data_image中
// 并且控制sdram_rd_req信号
reg[15:0] uart_data_image;
reg get_image;

always @(posedge sdram_read_ack or negedge rst_n or posedge get_image)
begin
    if (!rst_n)
    begin
        uart_data_image <= 16'b0;
        sdram_rd_req <= 1'b0;
    end
    else
    begin
        if (sdram_read_ack)
        begin
            uart_data_image  <= din;
            sdram_rd_req <= 1'b0;
        end
        else if (get_image)
        begin
            sdram_rd_req <= 1'b1;
        end
    end
end




reg [7:0] uart_data;
reg [7:0] uart_op_index;

reg uart_write_en;
wire busy;

// uart 控制器
UART_CONTROLLER_WRITE uart_011(

.rst(rst_n),
.clk(clk),
.uart_pin(uart_pin),
.WR(uart_write_en), // 1 is write DO NOT change it while busy
.write_data(uart_data),
.busy(busy)
);

reg [3:0] clock_skipper;

reg [16:0] sended_pixel_counter;   // 发送像素计数器
reg [3:0] send_pixel_state;         // 发送像素状态机
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        uart_op_index <= 8'b0;
        uart_write_en <= 1'b0;
        clock_skipper <= 4'b0;
        sended_pixel_counter <= 17'b0;
        send_pixel_state <= 4'b0;
    end
    else
    begin
        if (clock_skipper == 4'b1111)
        begin
            clock_skipper <= 4'b0;
            if (!busy && en)            // 串口空闲，开始发送
            begin
                case (uart_op_index)
                    8'd0: begin
                        uart_data <= 8'd105; // i
                        uart_write_en <= 1'b0;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd1: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd2: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd109; // m
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd3: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd4: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd97; // a
                        uart_op_index <= uart_op_index + 1;
                    end

                    8'd5: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd6: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd103; // g
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd7: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd8: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd101; // e
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd9: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd10: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd58; // :
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd11: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd12: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd13: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end

                    8'd14: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd44; // ,
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd15: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd16: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd49; // 1
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd17: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd18: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd53; // 5 
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd19: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd20: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd51; // 3
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd21: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd22: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd54; // 6
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd23: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd24: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd25: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd26: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd27: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd28: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd44; // ,
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd29: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd30: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd51; // 3
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd31: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd32: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd50; // 2
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd33: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd34: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd35: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd36: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd44; // ,
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd37: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd38: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd50; // 2
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd39: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd40: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd52; // 4
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd41: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd42: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd43: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd44: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd44; // ,
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd45: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd46: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd48; // 0
                        uart_op_index <= uart_op_index + 1;
                    end

                    8'd47: begin
                        //uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd48: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd55; // 7
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd49: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd50: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd10; // \n
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd51: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd52: begin
                        if (sended_pixel_counter < 17'd76800)
                        begin
                            case (send_pixel_state)
                                4'd0: begin
                                    get_image <= 1'b1;
                                    send_pixel_state <= send_pixel_state + 1;
                                end

                                4'd1: begin
                                    send_pixel_state <= send_pixel_state + 1;
                                end

                                4'd2: begin
                                    get_image <= 1'b0;
                                    uart_data <= uart_data_image[7:0];
                                    uart_write_en <= 1'b0;
                                    send_pixel_state <= send_pixel_state + 1;
                                end
                                4'd3: begin
                                    uart_write_en <= 1'b1;
                                    send_pixel_state <= send_pixel_state + 1;
                                end
                                4'd4: begin
                                    uart_data <= uart_data_image[15:8];
                                    uart_write_en <= 1'b0;
                                    send_pixel_state <= send_pixel_state + 1;
                                end
                                4'd5: begin
                                    uart_write_en <= 1'b1;
                                    sended_pixel_counter <= sended_pixel_counter + 1;
                                    send_pixel_state <= 4'd0;
                                end
                            endcase
                        end
                        else
                        begin
                            uart_op_index <= uart_op_index + 1;
                        end
                    end
                    8'd53: begin
                        uart_write_en <= 1'b0;
                        uart_data <= 8'd10; // \n
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd54: begin
                        uart_write_en <= 1'b1;
                        uart_op_index <= uart_op_index + 1;
                    end
                    8'd55: begin
                        uart_write_en <= 1'b0;

                    end

                    
                    default: begin
                        uart_op_index <= 8'b0;
                    end
                endcase
            end
        end
        else
        begin
            clock_skipper <= clock_skipper + 4'b1;
        end
    end
end
endmodule