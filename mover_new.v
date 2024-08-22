module  full_mover(
    input clk,     // 50M 主时钟
    input clk_slow, // 低速，逻辑时钟
    input clk_10hz, // 10HZ 时钟 用于延迟计时
    input rst_n,

    input [8:0] square_start_x, // 方形x位置
    input [7:0] square_start_y, // 方形y位置
    input [8:0] circle_start_x, // 圆形x位置
    input [7:0] circle_start_y, // 圆形y位置 
    input [8:0] hexagon_start_x, // 六边形x位置
    input [7:0] hexagon_start_y, // 六边形y位置

    input left_or_right, // 左右选择

    input [8:0] square_left,
    input [8:0] square_right,


    output reg [1:0] color_select, // red blue yellow black

    input process_ok, // 图形处理完成
    input en,          // 使能
    input move_to_home,  // 回到停泊位置
    output reg pump_enable, // 气泵使能
    output reg mov_complete,  // 搬运完成

    output reg sub_module_reset, // 对子模块复位

    output uart_pin           // 舵机串口输出
);

// 舵机停泊位置
`define SERVO_0_PARK 12'd1529
`define SERVO_1_PARK 12'd1840
`define SERVO_2_PARK 12'd1199
`define SERVO_3_PARK 12'd0842

`define RUN_SERVO_0_TIME 5'd8
`define RUN_SERVO_1_TIME 5'd8
`define RUN_SERVO_2_TIME 5'd5
`define RUN_SERVO_3_TIME 5'd5

`define RUN_AFTER_0 5'd0
`define RUN_AFTER_1 5'd0
`define RUN_AFTER_2 5'd0
`define RUN_AFTER_3 5'd0

`define PARK_SERVO_0_TIME 5'd1
`define PARK_SERVO_1_TIME 5'd1
`define PARK_SERVO_2_TIME 5'd1
`define PARK_SERVO_3_TIME 5'd1

`define PARK_AFTER_0 5'd1
`define PARK_AFTER_1 5'd1
`define PARK_AFTER_2 5'd1
`define PARK_AFTER_3 5'd1


reg [5:0] color_select_state_machine; // 选择颜色状态机
reg [5:0] shape_operation_state_machine; // 形状选择状态机
reg shape_operation_en;                  // 形状选择使能
reg [5:0] move_state_machine;            // 搬运状态机
reg move_operation_en;                  // 搬运使能
reg [3:0] servo_id;                      // 舵机ID


reg [8:0] start_x_buf;                  // 当前操作的图形x位置
reg [8:0] start_y_buf;                  // 当前操作的图形y位置

reg [4:0] delay_compare;                 // 延迟比较值
reg [4:0] delay_counter;                 // 延迟计数器
reg delay_output;                          // 延迟输出
reg delay_en;                             // 延迟使能

reg [3:0] move_seconds;                 // 舵机移动秒数
reg [3:0] move_hundreds_milliseconds;   // 舵机移动百分之一秒数

wire send_complete;                      // 舵机发送完成
reg servo_go;                               // 舵机发送使能
reg [15:0] send_angle;                      // 舵机发送角度
reg [5:0] target_lut_address_base;          // 目标放置位置的LUT基地址

reg [16:0] correct_angle_serovo;            // 修正后的舵机角度 

always @(posedge clk_10hz or negedge rst_n or negedge delay_en)
begin
    if (!rst_n || !delay_en)
    begin
        delay_counter <= 5'b0;
        delay_output <= 1'b0;
    end
    else
    begin
        if (delay_counter == delay_compare) // 延迟达到delay_compare后输出延迟结束
        begin
            delay_counter <= 5'b0;
            delay_output <= 1'b1;
        end
        else
            delay_counter <= delay_counter + 5'b1;
    end
end


// 主状态机 色彩循环，顺序红蓝黄黑
always @(posedge clk_slow or negedge rst_n or negedge en)
begin
    if (!rst_n || !en)
    begin
        shape_operation_en <= 1'b0;
        sub_module_reset <= 1'b0;
        color_select_state_machine <= 6'b0;
        color_select <= 2'b00;          // 先处理红色
        mov_complete <= 1'b0;
    end
    else
    begin
        if (en)
        begin
            case(color_select_state_machine)
                6'd0:
                begin
                    sub_module_reset <= 1'b0;
                    color_select <=  2'b00;
                    color_select_state_machine <= color_select_state_machine + 6'd1;
                end
                6'd1:
                begin
                    sub_module_reset <= 1'b0;  // 对子模块复位，准备下一次操作
                    color_select_state_machine <= color_select_state_machine + 6'd1;
                end
                6'd2:
                begin
                    sub_module_reset <= 1'b1;
                    color_select_state_machine <= color_select_state_machine + 6'd1;
                end
                6'd3:
                begin
                    if (process_ok)            // 等待图形处理完成
                    begin
                        color_select_state_machine <= color_select_state_machine + 6'd1;
                        shape_operation_en <= 1'b1;    // 开始选择图形并处理
                    end
                end
                6'd4:
                begin
                    if (shape_operation_state_machine == 6'd12)  // 等待图形处理完成
                    begin
                        color_select_state_machine <= color_select_state_machine + 6'd1;
                        shape_operation_en <= 1'b0;
                    end
                end
                6'd5:
                begin
                   if (color_select != 2'b11)               // 选择下一个颜色
                    begin
                           color_select_state_machine <= 6'd1;
                           color_select <= color_select + 2'b01;
                    end
                    else
                    begin
                        color_select_state_machine <= 6'd1;
                        color_select <=  2'b00;
                    end
                end
            endcase     
        end   
    end
end

// 状态机 选择图形
always @(posedge clk_slow or negedge rst_n or negedge shape_operation_en)
begin
    if (!rst_n || !shape_operation_en)
    begin
        shape_operation_state_machine <= 6'b0;
        start_x_buf <= 9'b0;
        start_y_buf <= 9'b0;
        target_lut_address_base <= 6'b0;
        move_operation_en <= 1'b0;
    end
    else
    begin
        if (shape_operation_en)
        begin
            case(shape_operation_state_machine)
                6'd0:
                begin
                    
                    if (square_start_x != 9'b0 && square_start_y != 9'b0)//先处理方形，没有方形则跳过
                    begin
                        start_x_buf <= square_start_x;
                        start_y_buf <= square_start_y;
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                    end
                    else
                    begin
                        shape_operation_state_machine <= 6'd4;
                    end
                    
                    case(color_select)          // 根据当前颜色和形状选择对应的LUT基础地址
                        2'b00:
                        begin
                            target_lut_address_base <= 6'd0 + 6'd0;
                        end
                        2'b01:
                        begin
                            target_lut_address_base <= 6'd12 + 6'd0;
                        end
                        2'b10:
                        begin
                            target_lut_address_base <= 6'd24 + 6'd0;
                        end
                        2'b11:
                        begin
                            target_lut_address_base <= 6'd36 + 6'd0;
                        end
                    endcase
                end
                6'd1:
                begin
                    
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd2:
                begin
                    move_operation_en <= 1'b1;   // 开始搬运
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd3:
                begin
                    if (move_state_machine == 6'd57)    // 搬运完成
                    begin
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                        move_operation_en <= 1'b0;
                    end
                end
                6'd4:
                begin
                    //shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                    // start_x_buf <= circle_start_x;
                    // start_y_buf <= circle_start_y;
                    if (circle_start_x != 9'b0 && circle_start_y != 9'b0) //处理圆形，没有圆形则跳过
                    begin
                        start_x_buf <= circle_start_x;
                        start_y_buf <= circle_start_y;
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                    end
                    else
                    begin
                        shape_operation_state_machine <= 6'd8;
                    end
                    case(color_select) // 根据当前颜色和形状选择对应的LUT基础地址
                        2'b00:
                        begin
                            target_lut_address_base <= 6'd0 + 6'd4;
                        end
                        2'b01:
                        begin
                            target_lut_address_base <= 6'd12 + 6'd4;
                        end
                        2'b10:
                        begin
                            target_lut_address_base <= 6'd24 + 6'd4;
                        end
                        2'b11:
                        begin
                            target_lut_address_base <= 6'd36 + 6'd4;
                        end
                    endcase
                end
                6'd5:
                begin
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd6:
                begin
                    move_operation_en <= 1'b1;
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd7:
                begin
                    if (move_state_machine == 6'd57)   // 搬运完成
                    begin
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                        move_operation_en <= 1'b0;
                    end
                end
                6'd8:
                begin
                    // shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                    // start_x_buf <= hexagon_start_x;
                    // start_y_buf <= hexagon_start_y;
                    if (hexagon_start_x != 9'b0 && hexagon_start_y != 9'b0)  //处理六边形，没有六边形则跳过
                    begin
                        start_x_buf <= hexagon_start_x;
                        start_y_buf <= hexagon_start_y;
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                    end
                    else
                    begin
                        shape_operation_state_machine <= 6'd12;
                    end
                    case(color_select)   // 根据当前颜色和形状选择对应的LUT基础地址
                        2'b00:
                        begin
                            target_lut_address_base <= 6'd0 + 6'd8;
                        end
                        2'b01:
                        begin
                            target_lut_address_base <= 6'd12 + 6'd8;
                        end
                        2'b10:
                        begin
                            target_lut_address_base <= 6'd24 + 6'd8;
                        end
                        2'b11:
                        begin
                            target_lut_address_base <= 6'd36 + 6'd8;
                        end
                    endcase
                end
                6'd9:
                begin
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd10:
                begin
                    move_operation_en <= 1'b1;
                    shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                end
                6'd11:
                begin
                    if (move_state_machine == 6'd57)   // 搬运完成
                    begin
                        shape_operation_state_machine <= shape_operation_state_machine + 6'd1;
                        move_operation_en <= 1'b0;
                    end
                end
                6'd12:  // 状态机结束，停止
                begin
                    
                end
            endcase
        end
    end
end

// 状态机 搬运流程
always @(posedge clk_slow or negedge rst_n)
begin
    if (!rst_n )
    begin
        move_state_machine <= 6'b0;
        delay_compare <= 5'b11111;
        move_seconds <= 4'b0;
        move_hundreds_milliseconds <= 4'b0;
        servo_go <= 1'b0;
        servo_id <= 4'b0;
        send_angle <= 16'b0; 
        delay_en <= 1'b0;
        target_lut_address <= 6'b0;
        pump_enable <= 1'b0;
    end
    else if (!move_operation_en && !move_to_home)
	begin
        move_state_machine <= 6'b0;
        delay_compare <= 5'b11111;
        move_seconds <= 4'b0;
        move_hundreds_milliseconds <= 4'b0;
        servo_go <= 1'b0;
        servo_id <= 4'b0;
        send_angle <= 16'b0; 
        delay_en <= 1'b0;
        target_lut_address <= 6'b0;
        pump_enable <= 1'b0;
    end
	else
    begin
        if (move_to_home)   // 如果输入回到停泊位置，则执行回到停泊位置的流程
        begin
            case (move_state_machine)
                6'd0:
                begin
                    move_state_machine <= move_state_machine + 6'd1;
                    servo_id <= 4'b1; 
                    send_angle <= `SERVO_1_PARK;
                    move_seconds <= 4'd0;
                    move_hundreds_milliseconds <= 4'd8;
                    servo_go <= 1'b0;
                    delay_en <= 1'b0;
                end
                6'd1:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd2:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd3:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd2; 
                        send_angle <= `SERVO_2_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd8;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd4:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd5:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd7;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd6:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'b0; 
                        send_angle <= `SERVO_0_PARK;
                        move_seconds <= 4'd1;
                        move_hundreds_milliseconds <= 4'd2;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd7:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd8:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd9:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd4; 
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd8;
                        send_angle <= `SERVO_3_PARK;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd10:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd11:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                    end
                    
                end
            endcase
        end
        else if (move_operation_en)   // 如果输入搬运使能，则执行搬运流程
        begin
            // 正常流程。
            case (move_state_machine)
                6'd0:
                begin
                    move_state_machine <= move_state_machine + 6'd1;
                    servo_id <= 4'd8; 
                    send_angle <= 16'd1500;
                    move_seconds <= 4'd0;
                    move_hundreds_milliseconds <= 4'd1;
                    servo_go <= 1'b0;
                    delay_en <= 1'b0;
                    angle_correction_rst <= 1'b0;
                end
                6'd1:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd2:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd3:       //第一步，从库区拿去目标
                begin
                    move_state_machine <= move_state_machine + 6'd1;
                    servo_id <= 4'b0; 
                    send_angle <= servo_angle_lut[47:36];
                    move_seconds <= 4'd0;
                    move_hundreds_milliseconds <= `RUN_SERVO_0_TIME;
                    servo_go <= 1'b0;
                    delay_en <= 1'b0;
                end
                6'd4:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd5:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `RUN_AFTER_0;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd6:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd4; 
                        send_angle <= servo_angle_lut[11:0];
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `RUN_SERVO_3_TIME;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd7:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd8:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `RUN_AFTER_3;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd9:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd2; 
                        send_angle <= servo_angle_lut[23:12]; // [48:32];
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `RUN_SERVO_2_TIME;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd10:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd11:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `RUN_AFTER_2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd12:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd1; 
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `RUN_SERVO_1_TIME;
                        send_angle <= servo_angle_lut[35:24];
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd13:
                begin
                    servo_go <= 1'b1;
                    pump_enable <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd14:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `RUN_AFTER_1;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd15: // 拿取到目标后，回到停泊位置
                begin
                    if (delay_output)
                    begin
                        move_state_machine <= move_state_machine + 6'd1;
                        servo_id <= 4'b1; 
                        send_angle <= `SERVO_1_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `PARK_SERVO_1_TIME;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                    end
                end
                6'd16:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd17:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `PARK_AFTER_1;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd18:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd2; 
                        send_angle <= `SERVO_2_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `PARK_SERVO_2_TIME;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd19:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd20:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `PARK_AFTER_2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd21:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd4; 
                        send_angle <= `SERVO_3_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `PARK_SERVO_3_TIME;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd22:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd23:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= `PARK_AFTER_3;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
								target_lut_address <= target_lut_address_base;
                    end
                end
                6'd24:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd0; 
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= `PARK_SERVO_0_TIME;
                        send_angle <= `SERVO_0_PARK;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd25:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
               
                end
                6'd26:
                begin
                    if (send_complete)
                    begin
                        angle_correction_rst <= 1'b1;
                        servo_go <= 1'b0;
                        delay_compare <= `PARK_AFTER_0;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end

                // 矫正角度
                6'd27:
                begin
                    if (delay_output)
                    begin
                        move_state_machine <= move_state_machine + 6'd1;
                        servo_id <= 4'd8; 
                        send_angle <= correct_angle_serovo;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd7;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                    end
                end
                6'd28:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd29:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd30: // 放置到另一侧的目标位置
                begin

                        move_state_machine <= move_state_machine + 6'd1;
                        servo_id <= 4'b0; 
                        send_angle <= servo_put_target;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd5;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                end
                6'd31:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                    target_lut_address <= target_lut_address_base + 3;  // 根据当前操作的舵机需要添加的偏移量
                end
                6'd32:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd33:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd4; 
                        send_angle <= servo_put_target;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd3;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd34:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                    target_lut_address <= target_lut_address_base + 2; // 根据当前操作的舵机需要添加的偏移量
                end
                6'd35:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd36:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd2; 
                        send_angle <= servo_put_target;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd3;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd37:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                    target_lut_address <= target_lut_address_base + 1;
                end
                6'd38:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd4;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd39:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd1; 
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd4;
                        send_angle <= servo_put_target;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd40:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd41:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd6;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd42:
                begin
                    if (delay_output)
                    begin
                        pump_enable <= 1'b0;
                        delay_compare <= 5'd05;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;             
                    end
                end
                6'd43:
                begin
                    delay_en <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;   
                end
                6'd44: // 再次回到停泊位置，等待下一次搬运
                begin
                    if (delay_output)
                    begin
                        pump_enable <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                        servo_id <= 4'b1; 
                        send_angle <= `SERVO_1_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd3;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                    end
                end
                6'd45:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd46:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd1;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd47:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd2; 
                        send_angle <= `SERVO_2_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd3;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd48:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd49:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd1;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd50:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd4; 
                        send_angle <= `SERVO_3_PARK;
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd3;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd51:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                end
                6'd52:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd4;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd53:
                begin
                    if (delay_output)
                    begin
                        servo_id <= 4'd0; 
                        move_seconds <= 4'd0;
                        move_hundreds_milliseconds <= 4'd5;
                        send_angle <= `SERVO_0_PARK;
                        servo_go <= 1'b0;
                        delay_en <= 1'b0;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd54:
                begin
                    servo_go <= 1'b1;
                    move_state_machine <= move_state_machine + 6'd1;
                    target_lut_address <= target_lut_address_base + 1;
                end
                6'd55:
                begin
                    if (send_complete)
                    begin
                        servo_go <= 1'b0;
                        delay_compare <= 5'd2;
                        delay_en <= 1'b1;
                        move_state_machine <= move_state_machine + 6'd1;
                    end
                end
                6'd56:
                begin
                    if (delay_output)
                    begin
                        move_state_machine <= move_state_machine + 6'd1;
                        delay_en <= 1'b0;
                        delay_compare <= 5'b11111;
                    end
                end
                6'd57:     // 搬运状态机结束，停止
                begin
                end
            endcase
        end
    end
end

// 将坐标映射到查找表序号
wire [12:0] x_reMap /*synthesis preserve*/= (start_x_buf- 83)/ 2 ;
wire [12:0] y_reMap /*synthesis preserve*/= ((start_y_buf- 100 )/2) ;
wire [12:0] xy_pos/*synthesis preserve*/;
assign xy_pos = x_reMap+y_reMap*81 ;


reg [5:0] target_lut_address;
wire [11:0] servo_put_target;

servo_target_lut   servo_target_lut_inst  (
	.address ( target_lut_address ),
	.clock ( clk ),
	.q ( servo_put_target )
	);

wire [47:0] servo_angle_lut;
reg angle_cov_rst;
servo_lut  servo_lut_ins (
    .address(xy_pos[11:0]),
    .clock(clk),
    .q(servo_angle_lut)
    );


// 舵机控制器
servo_controller servo_ins(
    .clk(clk),
    .rst(rst_n),
    .uart_pin(uart_pin),
    .angle_in(send_angle),
    .servo_id(servo_id),
    .move_seconds(move_seconds),
    .move_hundreds_milliseconds(move_hundreds_milliseconds),
    .go(servo_go),
    .send_complete(send_complete)
    );

reg angle_correction_rst;
angle_correction angle_corr(
    .clk(clk),
    .rst_n(angle_correction_rst),
    .source_angle(servo_angle_lut[47:36]),
    .target_angle(servo_put_target),
    .x_left(square_left),
    .x_right(square_right),
    .left_or_right(left_or_right),
    .corrected_angle(correct_angle_serovo)
);



endmodule