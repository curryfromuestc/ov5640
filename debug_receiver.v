module debug_receiver( //暂未启用
    input clk,
    input rst_n,
    input uart_pin,

    input [1:0] color_select, //顺序 red blue yellow black

    output reg [4:0] red_ub,
    output reg [4:0] red_lb,
    output reg [5:0] green_ub,
    output reg [5:0] green_lb,
    output reg [4:0] blue_ub,
    output reg [4:0] blue_lb, 

    output reg data_valid

);

always @(*)
begin
    case(color_select)
    2'b00:
    begin
        red_ub <= red_buf_red_ub;
        red_lb <= red_buf_red_lb;
        green_ub <= red_buf_green_ub;
        green_lb <= red_buf_green_lb;
        blue_ub <= red_buf_blue_ub;
        blue_lb <= red_buf_blue_lb;
    end
    2'b01:
    begin
        red_ub <= blue_buf_red_ub;
        red_lb <= blue_buf_red_lb;
        green_ub <= blue_buf_green_ub;
        green_lb <= blue_buf_green_lb;
        blue_ub <= blue_buf_blue_ub;
        blue_lb <= blue_buf_blue_lb;
    end
    2'b10:
    begin
        red_ub <= yellow_buf_red_ub;
        red_lb <= yellow_buf_red_lb;
        green_ub <= yellow_buf_green_ub;
        green_lb <= yellow_buf_green_lb;
        blue_ub <= yellow_buf_blue_ub;
        blue_lb <= yellow_buf_blue_lb;
    end
    2'b11:
    begin
        red_ub <= black_buf_red_ub;
        red_lb <= black_buf_red_lb;
        green_ub <= black_buf_green_ub;
        green_lb <= black_buf_green_lb;
        blue_ub <= black_buf_blue_ub;
        blue_lb <= black_buf_blue_lb;
    end
    endcase
end

reg [4:0] red_buf_red_ub;
reg [4:0] red_buf_red_lb;
reg [5:0] red_buf_green_ub;
reg [5:0] red_buf_green_lb;
reg [4:0] red_buf_blue_ub;
reg [4:0] red_buf_blue_lb;

reg [4:0] blue_buf_red_ub;
reg [4:0] blue_buf_red_lb;
reg [5:0] blue_buf_green_ub;
reg [5:0] blue_buf_green_lb;
reg [4:0] blue_buf_blue_ub;
reg [4:0] blue_buf_blue_lb;

reg [4:0] yellow_buf_red_ub;
reg [4:0] yellow_buf_red_lb;
reg [5:0] yellow_buf_green_ub;
reg [5:0] yellow_buf_green_lb;
reg [4:0] yellow_buf_blue_ub;
reg [4:0] yellow_buf_blue_lb;

reg [4:0] black_buf_red_ub;
reg [4:0] black_buf_red_lb;
reg [5:0] black_buf_green_ub;
reg [5:0] black_buf_green_lb;
reg [4:0] black_buf_blue_ub;
reg [4:0] black_buf_blue_lb;

reg [7:0] uart_buf_red_ub;
reg [7:0] uart_buf_red_lb;
reg [7:0] uart_buf_green_ub;
reg [7:0] uart_buf_green_lb;
reg [7:0] uart_buf_blue_ub;
reg [7:0] uart_buf_blue_lb;

reg [1:0] colcr_write_select;
reg write_enable;

always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        // 初始化色彩预设值
        red_buf_red_ub <= (8'd178 >> 3);
        red_buf_red_lb <= (8'd100 >> 3);
        red_buf_green_ub <= (8'd49 >> 2);
        red_buf_green_lb <= (8'h00 >> 2);
        red_buf_blue_ub <= (8'd58 >> 3);
        red_buf_blue_lb <= (8'd06 >> 3);

        blue_buf_red_ub <= (8'd34 >> 3);
        blue_buf_red_lb <= (8'd00 >> 3);
        blue_buf_green_ub <= (8'd54 >> 2);
        blue_buf_green_lb <= (8'd10 >> 2);
        blue_buf_blue_ub <= (8'd122 >> 3);
        blue_buf_blue_lb <= (8'd54 >> 3);

        yellow_buf_red_ub <= (8'd255 >> 3);
        yellow_buf_red_lb <= (8'd208 >> 3);
        yellow_buf_green_ub <= (8'd222 >> 2);
        yellow_buf_green_lb <= (8'd166 >> 2);
        yellow_buf_blue_ub <= (8'd82 >> 3);
        yellow_buf_blue_lb <= (8'd22 >> 3);

        black_buf_red_ub <= (8'd34 >> 3);
        black_buf_red_lb <= (8'h00 >> 3);
        black_buf_green_ub <= (8'd42 >> 2);
        black_buf_green_lb <= (8'h00 >> 2);
        black_buf_blue_ub <= (8'd34 >> 3);
        black_buf_blue_lb <= (8'h00 >> 3);
    end
    else
    begin
		if (write_enable) // 当UART接收到完整数据后，再使能写入
        begin
            case (colcr_write_select)
            2'b00:
            begin
                red_buf_red_ub <= uart_buf_red_ub[7:3];
                red_buf_red_lb <= uart_buf_red_lb[7:3];
                red_buf_green_ub <= uart_buf_green_ub[7:2];
                red_buf_green_lb <= uart_buf_green_lb[7:2];
                red_buf_blue_ub <= uart_buf_blue_ub[7:3];
                red_buf_blue_lb <= uart_buf_blue_lb[7:3];
            end
            2'b01:
            begin
                blue_buf_red_ub <= uart_buf_red_ub[7:3];
                blue_buf_red_lb <= uart_buf_red_lb[7:3];
                blue_buf_green_ub <= uart_buf_green_ub[7:2];
                blue_buf_green_lb <= uart_buf_green_lb[7:2];
                blue_buf_blue_ub <= uart_buf_blue_ub[7:3];
                blue_buf_blue_lb <= uart_buf_blue_lb[7:3];
            end
            2'b10:
            begin
                yellow_buf_red_ub <= uart_buf_red_ub[7:3];
                yellow_buf_red_lb <= uart_buf_red_lb[7:3];
                yellow_buf_green_ub <= uart_buf_green_ub[7:2];
                yellow_buf_green_lb <= uart_buf_green_lb[7:2];
                yellow_buf_blue_ub <= uart_buf_blue_ub[7:3];
                yellow_buf_blue_lb <= uart_buf_blue_lb[7:3];
            end
            2'b11:
            begin
                black_buf_red_ub <= uart_buf_red_ub[7:3];
                black_buf_red_lb <= uart_buf_red_lb[7:3];
                black_buf_green_ub <= uart_buf_green_ub[7:2];
                black_buf_green_lb <= uart_buf_green_lb[7:2];
                black_buf_blue_ub <= uart_buf_blue_ub[7:3];
                black_buf_blue_lb <= uart_buf_blue_lb[7:3];
            end
            endcase
        end
	end
end

reg [4:0] receiver_state;

// 在uart接收到数据后，解析并存储对应寄存器
// 协议 /x:r:lu,g:lu,b:lu// x为目标颜色选择，lu分别代表上下限，使用RGB888标准
always @(negedge busy or negedge rst_n)
begin
    if (!rst_n)
    begin
        receiver_state <= 5'b0;
        data_valid <= 1'b0;
        colcr_write_select <= 2'b00;
        write_enable <= 1'b0;
    end
    else
    begin
        case(receiver_state)
        5'd0:
        begin
            if (uart_data == 8'h2F) // / 
            begin
                receiver_state <= receiver_state + 5'd1;
            end
        end
        5'd1:
        begin
            case (uart_data)
                8'h72: begin colcr_write_select <= 2'b00; receiver_state <= receiver_state + 5'd1;end  // r
                8'h62: begin colcr_write_select <= 2'b01; receiver_state <= receiver_state + 5'd1;end // b
                8'h79: begin colcr_write_select <= 2'b10; receiver_state <= receiver_state + 5'd1;end// y
                8'h68: begin colcr_write_select <= 2'b11; receiver_state <= receiver_state + 5'd1;end // black
                default : 
                    begin
                        if (uart_data == 8'h2F) // / //用于连续判断
                        begin
                            receiver_state <= 5'd1;
                        end
                        else
                        begin
                            receiver_state <= 5'd0;
                        end
                    end
            endcase
        end
        5'd2:
        begin
            if (uart_data == 8'h3A) // :
            begin
                receiver_state <= receiver_state + 5'd1;
                data_valid <= 1'b0;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd3:
        begin
            if (uart_data == 8'h72) // r
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd4:
        begin
            if (uart_data == 8'h3A) // :
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd5:
        begin
            uart_buf_red_lb <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd6:
        begin
            uart_buf_red_ub <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd7:
        begin
            if (uart_data == 8'h2C) // ,
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd8:
        begin
            if (uart_data == 8'h67) // g
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd9:
        begin
            if (uart_data == 8'h3A) // :
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd10:
        begin
            uart_buf_green_lb <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd11:
        begin
            uart_buf_green_ub <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd12:
        begin
            if (uart_data == 8'h2C) // ,
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd13:
        begin
            if (uart_data == 8'h62) // b
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd14:
        begin
            if (uart_data == 8'h3A) // :
            begin
                receiver_state <= receiver_state + 5'd1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd15:
        begin
            uart_buf_blue_lb <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd16:
        begin
            uart_buf_blue_ub <= uart_data;
            receiver_state <= receiver_state + 5'd1;
        end
        5'd17:
        begin
            if (uart_data == 8'h2F) // /
            begin
                receiver_state <= receiver_state + 5'd1;
                write_enable <= 1'b1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end
        5'd18:
        begin
            if (uart_data == 8'h2F) // /
            begin
                receiver_state <= 0;
                write_enable <= 1'b0;
                data_valid <= 1'b1;
            end
            else
            begin
                receiver_state <= 5'd0;
            end
        end

    endcase
    end
end

wire [7:0] uart_data;
wire busy;

// 串口接收模块
UART_CONTROLLER_READ uart_0(
.rst(rst_n),
.clk(clk),
.uart_pin(uart_pin),
.read_data(uart_data),
.busy(busy)
);


endmodule