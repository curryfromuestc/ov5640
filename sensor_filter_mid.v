module sensor_filter_mid(
    input clk,       // 50M 主时钟
    input rst_n,    // 复位信号
    input [15:0] sensor_data, // 像素数据
    input req_in,               // 请求信号
    output reg req_out,      // 请求信号

    input ack_in,           // 应答信号
    output reg ack_out,     // 应答信号输出

    input [1:0] color_select,

    output reg color_out   // 二值化后数据

);

reg [7:0] red_color_data;   // 红色数据
reg [7:0] green_color_data; // 绿色数据
reg [7:0] blue_color_data;  // 蓝色数据

reg [7:0] y_ub;
reg [7:0] y_lb;
reg [7:0] u_ub;
reg [7:0] u_lb;
reg [7:0] v_ub;
reg [7:0] v_lb;

always@(*)
begin
    case (color_select)
    2'b00 :               // red
    begin
        y_lb <= 8'd20 ;
        y_ub <= 8'd100 ;
        u_lb <= 8'd80 ; 
        u_ub <= 8'd137 ;
        v_lb <= 8'd155 ;
        v_ub <= 8'd228 ;
    end
    2'b01 :                 // blue
    begin
        y_lb <= 8'd0 ;
        y_ub <= 8'd80 ;
        u_lb <= 8'd130 ; 
        u_ub <= 8'd180 ;
        v_lb <= 8'd95 ;
        v_ub <= 8'd135 ;
    end
    2'b10 :                 // yellow
    begin
        y_lb <= 8'd80 ;
        y_ub <= 8'd220 ;
        u_lb <= 8'd15 ; 
        u_ub <= 8'd85 ;
        v_lb <= 8'd125 ;
        v_ub <= 8'd187 ;
    end
    2'b11 :                 //black
    begin
        y_lb <= 8'd00 ;
        y_ub <= 8'd50 ;
        u_lb <= 8'd103 ; 
        u_ub <= 8'd145 ;
        v_lb <= 8'd103 ;
        v_ub <= 8'd145 ;
    end
    endcase
end


// 对请求信号管理，请求输入上升沿拉高，应答信号上升沿拉低
always @(posedge req_in or posedge ack_in or negedge rst_n)
begin
    if (~rst_n)
    begin
        req_out <= 1'b0;
    end
    else
    begin
        if (ack_in)
        begin
            req_out <= 1'b0;
        end
        else
        begin
            req_out <= 1'b1;
        end
    end
end

//检测ack_in上升沿，并延迟一周期
reg ack_in_last;
reg ack_in_last_1;
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        ack_in_last <= 1'b0;
        ack_in_last_1 <= 1'b0;
    end
    else
    begin
        ack_in_last <= ack_in;
        ack_in_last_1 <= ack_in_last;
    end

end
wire ack_in_rise = ack_in_last && ~ack_in_last_1;

reg [2:0] work_state; // 工作状态机

reg [22:0] Y;

reg [22:0] U_m;
reg [22:0] U;

reg [22:0] V_m;
reg [22:0] V;

always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        color_out <= 1'b0;
        work_state <= 3'b00;
		red_color_data <= 5'b0;
        green_color_data <= 6'b0;
        blue_color_data <= 5'b0;
        ack_out <= 1'b0;
    end
    else
    begin
        if (ack_in_rise && req_in)  // 请求信号上升沿
        begin
            work_state <= 3'd2;
            red_color_data <= {sensor_data[15:11], 3'b000};                   // 将16bit数据拆分回RGB565
            green_color_data <={sensor_data[10:5] , 2'b00}; 
            blue_color_data <= {sensor_data[4:0], 3'b000};
        end
        else if (work_state == 3'd2)    
        begin
            Y <=  23'd9797 * red_color_data + 23'd19234 * green_color_data + 23'd3735 * blue_color_data;
            U_m <= 23'd5537 * red_color_data + 23'd10846 * green_color_data;
            U <= 23'd4194304;
            V <= 23'd4194304;
            V_m <= 23'd14385 * green_color_data + 23'd2654 * blue_color_data;
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd3)    
        begin
            U <= U - U_m;
            V <= V - V_m;
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd4)    
        begin
            U <= U + 23'd16384 * blue_color_data;
            V <= V + 23'd16384 * red_color_data;
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd5)    
        begin
            U <= {15'b0, U[22:15]};
            V <= {15'b0,V[22:15]};
            Y <= {15'b0,Y[22:15]};
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd6)    
        begin
            if (Y > y_lb & Y < y_ub &  U > u_lb & U < u_ub & V > v_lb & V < v_ub)
            begin
                color_out <= 1'b1;
            end
            else
            begin
                color_out <= 1'b0;
            end
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd7)    
        begin
            ack_out <= 1'b1;
            work_state <= work_state + 1;
        end
        else if (work_state == 3'd8 && !req_in)    // 请求信号下降后，清除应答信号
        begin
            ack_out <= 1'b0;
            work_state <= 2'b00;
        end
    end
end

endmodule