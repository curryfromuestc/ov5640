module shape_finder(
    input clk,
    input rst_n,

    input en,
    
    output reg data_req,
    input data_ack,

    input data_in,

    output reg analysis_done,

    output reg [8:0] hexagon_x,
    output reg [7:0] hexagon_y,

    output reg [8:0] circle_x,
    output reg [7:0] circle_y,

    output reg [8:0] square_x,
    output reg [7:0] square_y,

    output reg [8:0] square_left,
    output reg [8:0] square_right,

    output reg left_or_right

);

`define param_min_area 12'd500  // 面积阈值，小于认为是噪声

reg [8:0] current_x;
reg [7:0] current_y;

// 区块缓存
reg [10:0] area_1;
reg [8:0] x_min_1;
reg [8:0] x_max_1;
reg [7:0] y_min_1;
reg [7:0] y_max_1;
reg [8:0] x_min_in_line_1;
reg [8:0] x_max_in_line_1;
reg [8:0] x_min_in_line_current_1;
reg [8:0] x_max_in_line_current_1;
reg [7:0] last_operate_y_1; 

reg [10:0] area_2;
reg [8:0] x_min_2;
reg [8:0] x_max_2;
reg [7:0] y_min_2;
reg [7:0] y_max_2;
reg [8:0] x_min_in_line_2;
reg [8:0] x_max_in_line_2;
reg [8:0] x_min_in_line_current_2;
reg [8:0] x_max_in_line_current_2;
reg [7:0] last_operate_y_2; 


reg [10:0] area_3;
reg [8:0] x_min_3;
reg [8:0] x_max_3;
reg [7:0] y_min_3;
reg [7:0] y_max_3;
reg [8:0] x_min_in_line_3;
reg [8:0] x_max_in_line_3;
reg [8:0] x_min_in_line_current_3;
reg [8:0] x_max_in_line_current_3;
reg [7:0] last_operate_y_3; 

reg [10:0] area_4;
reg [8:0] x_min_4;
reg [8:0] x_max_4;
reg [7:0] y_min_4;
reg [7:0] y_max_4;
reg [8:0] x_min_in_line_4;
reg [8:0] x_max_in_line_4;
reg [8:0] x_min_in_line_current_4;
reg [8:0] x_max_in_line_current_4;
reg [7:0] last_operate_y_4; 

reg [10:0] area_5;
reg [8:0] x_min_5;
reg [8:0] x_max_5;
reg [7:0] y_min_5;
reg [7:0] y_max_5;
reg [8:0] x_min_in_line_5;
reg [8:0] x_max_in_line_5;
reg [8:0] x_min_in_line_current_5;
reg [8:0] x_max_in_line_current_5;
reg [7:0] last_operate_y_5; 

reg [10:0] area_6;
reg [8:0] x_min_6;
reg [8:0] x_max_6;
reg [7:0] y_min_6;
reg [7:0] y_max_6;
reg [8:0] x_min_in_line_6;
reg [8:0] x_max_in_line_6;
reg [8:0] x_min_in_line_current_6;
reg [8:0] x_max_in_line_current_6;
reg [7:0] last_operate_y_6; 

reg [10:0] area_7;
reg [8:0] x_min_7;
reg [8:0] x_max_7;
reg [7:0] y_min_7;
reg [7:0] y_max_7;
reg [8:0] x_min_in_line_7;
reg [8:0] x_max_in_line_7;
reg [8:0] x_min_in_line_current_7;
reg [8:0] x_max_in_line_current_7;
reg [7:0] last_operate_y_7; 

reg [10:0] area_8;
reg [8:0] x_min_8;
reg [8:0] x_max_8;
reg [7:0] y_min_8;
reg [7:0] y_max_8;
reg [8:0] x_min_in_line_8;
reg [8:0] x_max_in_line_8;
reg [8:0] x_min_in_line_current_8;
reg [8:0] x_max_in_line_current_8;
reg [7:0] last_operate_y_8; 

// reg [10:0] area_9;
// reg [8:0] x_min_9;
// reg [8:0] x_max_9;
// reg [7:0] y_min_9;
// reg [7:0] y_max_9;
// reg [8:0] x_min_in_line_9;
// reg [8:0] x_max_in_line_9;
// reg [8:0] x_min_in_line_current_9;
// reg [8:0] x_max_in_line_current_9;
// reg [7:0] last_operate_y_9; 

// reg [10:0] area_10;
// reg [8:0] x_min_10;
// reg [8:0] x_max_10;
// reg [7:0] y_min_10;
// reg [7:0] y_max_10;
// reg [8:0] x_min_in_line_10;
// reg [8:0] x_max_in_line_10;
// reg [8:0] x_min_in_line_current_10;
// reg [8:0] x_max_in_line_current_10;
// reg [7:0] last_operate_y_10; 

reg [9:0] process_x_min;
reg [9:0] process_x_max;

reg capture_finished;
reg ready_for_req;

reg data_last;

wire data;   // 去除运行区域以外的数据
assign data = (current_x < 9'd58 | current_x > 9'd235 | current_y < 9'd86 | current_y > 9'd202 ) ? 1'b0 : data_in ;

wire could_merge;  // 判断是否可以合并
assign could_merge = 
(((process_x_max + process_x_min ) / 2 >= x_min_in_line_1 && (process_x_max + process_x_min ) /2 <= x_max_in_line_1) && (current_y == last_operate_y_1 + 1 || current_y == last_operate_y_1)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_2 && (process_x_max + process_x_min ) /2 <= x_max_in_line_2) && (current_y == last_operate_y_2 + 1 || current_y == last_operate_y_2)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_3 && (process_x_max + process_x_min ) /2 <= x_max_in_line_3) && (current_y == last_operate_y_3 + 1 || current_y == last_operate_y_3)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_4 && (process_x_max + process_x_min ) /2 <= x_max_in_line_4) && (current_y == last_operate_y_4 + 1 || current_y == last_operate_y_4)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_5 && (process_x_max + process_x_min ) /2 <= x_max_in_line_5) && (current_y == last_operate_y_5 + 1 || current_y == last_operate_y_5)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_6 && (process_x_max + process_x_min ) /2 <= x_max_in_line_6) && (current_y == last_operate_y_6 + 1 || current_y == last_operate_y_6)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_7 && (process_x_max + process_x_min ) /2 <= x_max_in_line_7) && (current_y == last_operate_y_7 + 1 || current_y == last_operate_y_7)) 
|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_8 && (process_x_max + process_x_min ) /2 <= x_max_in_line_8) && (current_y == last_operate_y_8 + 1 || current_y == last_operate_y_8));
//|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_9 && (process_x_max + process_x_min ) /2 <= x_max_in_line_9) && (current_y == last_operate_y_9 + 1 || current_y == last_operate_y_9));
//|| (((process_x_max + process_x_min ) / 2 >= x_min_in_line_10 && (process_x_max + process_x_min ) /2 <= x_max_in_line_10) && (current_y == last_operate_y_10 + 1 || current_y == last_operate_y_10));


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        ready_for_req <= 1'b1;
        process_x_max <= 10'd0;
        process_x_min <= 10'd0;
        data_last <= 1'b0;
        
        capture_finished <= 1'b0;

        data_req <= 1'b0;

        current_x <= 9'd321;
        current_y <= 8'd241;
        area_1 <= 11'd0;
        x_min_1 <= 9'd321;
        x_max_1 <= 9'd0;
        y_min_1 <= 8'd241;
        y_max_1 <= 8'd0;
        x_min_in_line_1 <= 9'd321;
        x_max_in_line_1 <= 9'd0;
        x_min_in_line_current_1 <= 9'd321;
        x_max_in_line_current_1 <= 9'd0;
        last_operate_y_1 <= 8'd241;

        area_2 <= 11'd0;
        x_min_2 <= 9'd321;
        x_max_2 <= 9'd0;
        y_min_2 <= 8'd241;
        y_max_2 <= 8'd0;
        x_min_in_line_2 <= 9'd321;
        x_max_in_line_2 <= 9'd0;
        x_min_in_line_current_2 <= 9'd321;
        x_max_in_line_current_2 <= 9'd0;
        last_operate_y_2 <= 8'd241;

        area_3 <= 11'd0;
        x_min_3 <= 9'd321;
        x_max_3 <= 9'd0;
        y_min_3 <= 8'd241;
        y_max_3 <= 8'd0;
        x_min_in_line_3 <= 9'd321;
        x_max_in_line_3 <= 9'd0;
        x_min_in_line_current_3 <= 9'd321;
        x_max_in_line_current_3 <= 9'd0;
        last_operate_y_3 <= 8'd241;
        
        area_4 <= 11'd0;
        x_min_4 <= 9'd321;
        x_max_4 <= 9'd0;
        y_min_4 <= 8'd241;
        y_max_4 <= 8'd0;
        x_min_in_line_4 <= 9'd321;
        x_max_in_line_4 <= 9'd0;
        x_min_in_line_current_4 <= 9'd321;
        x_max_in_line_current_4 <= 9'd0;
        last_operate_y_4 <= 8'd241;

        area_5 <= 11'd0;
        x_min_5 <= 9'd321;
        x_max_5 <= 9'd0;
        y_min_5 <= 8'd241;
        y_max_5 <= 8'd0;
        x_min_in_line_5 <= 9'd321;
        x_max_in_line_5 <= 9'd0;
        x_min_in_line_current_5 <= 9'd321;
        x_max_in_line_current_5 <= 9'd0;
        last_operate_y_5 <= 8'd241;

        area_6 <= 11'd0;
        x_min_6 <= 9'd321;
        x_max_6 <= 9'd0;
        y_min_6 <= 8'd241;
        y_max_6 <= 8'd0;
        x_min_in_line_6 <= 9'd321;
        x_max_in_line_6 <= 9'd0;
        x_min_in_line_current_6 <= 9'd321;
        x_max_in_line_current_6 <= 9'd0;
        last_operate_y_6 <= 8'd241;

        area_7 <= 11'd0;
        x_min_7 <= 9'd321;
        x_max_7 <= 9'd0;
        y_min_7 <= 8'd241;
        y_max_7 <= 8'd0;
        x_min_in_line_7 <= 9'd321;
        x_max_in_line_7 <= 9'd0;
        x_min_in_line_current_7 <= 9'd321;
        x_max_in_line_current_7 <= 9'd0;
        last_operate_y_7 <= 8'd241;

        area_8 <= 11'd0;
        x_min_8 <= 9'd321;
        x_max_8 <= 9'd0;
        y_min_8 <= 8'd241;
        y_max_8 <= 8'd0;
        x_min_in_line_8 <= 9'd321;
        x_max_in_line_8 <= 9'd0;
        x_min_in_line_current_8 <= 9'd321;
        x_max_in_line_current_8 <= 9'd0;
        last_operate_y_8 <= 8'd241;

        // area_9 <= 11'd0;
        // x_min_9 <= 9'd321;
        // x_max_9 <= 9'd0;
        // y_min_9 <= 8'd241;
        // y_max_9 <= 8'd0;
        // x_min_in_line_9 <= 9'd321;
        // x_max_in_line_9 <= 9'd0;
        // x_min_in_line_current_9 <= 9'd321;
        // x_max_in_line_current_9 <= 9'd0;
        // last_operate_y_9 <= 8'd241;

        // area_10 <= 11'd0;
        // x_min_10 <= 9'd321;
        // x_max_10 <= 9'd0;
        // y_min_10 <= 8'd241;
        // y_max_10 <= 8'd0;
        // x_min_in_line_10 <= 9'd321;
        // x_max_in_line_10 <= 9'd0;
        // x_min_in_line_current_10 <= 9'd321;
        // x_max_in_line_current_10 <= 9'd0;
        // last_operate_y_10 <= 8'd241;
    end
    else
    begin
        if (en)
        begin
            if (ready_for_req)
            begin
                ready_for_req <= 1'b0;

                if (current_y == 9'd240 - 1)
                begin
                    data_req <= 1'b0;
                    capture_finished <= 1'b1;
                end
                else
                begin
                    data_req <= 1'b1;
                end

                if (current_x == 9'd321)
                begin
                    current_x <= 9'd0;
                    current_y <= 9'd0;
                end
                else
                begin
                    
                    if (current_x == (9'd320 - 9'd1))
                    begin
                        current_x <= 9'd0;
                        if (current_y < 9'd240 - 1 )
                        begin
                            // 换行
                            current_y <= current_y + 9'd1;
                            process_x_min <= 10'd0;
                            process_x_max <= 10'd0;
                            
                            x_min_in_line_current_1 <= 9'd321;
                            x_max_in_line_current_1 <= 9'd0;

                            x_min_in_line_current_2 <= 9'd321;
                            x_max_in_line_current_2 <= 9'd0;

                            x_min_in_line_current_3 <= 9'd321;
                            x_max_in_line_current_3 <= 9'd0;

                            x_min_in_line_current_4 <= 9'd321;
                            x_max_in_line_current_4 <= 9'd0;

                            x_min_in_line_current_5 <= 9'd321;
                            x_max_in_line_current_5 <= 9'd0;

                            x_min_in_line_current_6 <= 9'd321;
                            x_max_in_line_current_6 <= 9'd0;

                            x_min_in_line_current_7 <= 9'd321;
                            x_max_in_line_current_7 <= 9'd0;

                            x_min_in_line_current_8 <= 9'd321;
                            x_max_in_line_current_8 <= 9'd0;

                            // x_min_in_line_current_9 <= 9'd321;
                            // x_max_in_line_current_9 <= 9'd0;

                            // x_min_in_line_current_10 <= 9'd321;
                            // x_max_in_line_current_10 <= 9'd0;

                            // 无效区块回收
                            // if (current_y - last_operate_y_10 > 0 && last_operate_y_10 != 8'd241 && area_10 < `param_min_area)
                            // begin
                            //     x_min_in_line_10 <= 9'd321;
                            //     x_max_in_line_10 <= 9'd0;
                            //     last_operate_y_10 <= 9'd321;
                            //     x_min_10 <= 9'd321;
                            //     x_max_10 <= 9'd0;
                            //     y_min_10 <= 9'd241;
                            //     y_max_10 <= 9'd0;
                            //     area_10 <= 11'd0;
                            // end
                            // else
                            // begin
                            //     x_min_in_line_10 <= x_min_in_line_current_10;
                            //     x_max_in_line_10 <= x_max_in_line_current_10;
                            // end

                            // if (current_y - last_operate_y_9 > 0 && last_operate_y_9 != 8'd241 && area_9 < `param_min_area)
                            // begin
                            //     x_min_in_line_9 <= 9'd321;
                            //     x_max_in_line_9 <= 9'd0;
                            //     last_operate_y_9 <= 8'd241;
                            //     x_min_9 <= 9'd321;
                            //     x_max_9 <= 9'd0;
                            //     y_min_9 <= 8'd241;
                            //     y_max_9 <= 9'd0;
                            //     area_9 <= 11'd0;
                            // end
                            // else
                            // begin
                            //     x_min_in_line_9 <= x_min_in_line_current_9;
                            //     x_max_in_line_9 <= x_max_in_line_current_9;
                            // end

                            if (current_y - last_operate_y_8 > 0 && last_operate_y_8 != 8'd241 && area_8 < `param_min_area)
                            begin
                                x_min_in_line_8 <= 9'd321;
                                x_max_in_line_8 <= 9'd0;
                                last_operate_y_8 <= 8'd241;
                                x_min_8 <= 9'd321;
                                x_max_8 <= 9'd0;
                                y_min_8 <= 8'd241;
                                y_max_8 <= 8'd0;
                                area_8 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_8 <= x_min_in_line_current_8;
                                x_max_in_line_8 <= x_max_in_line_current_8;
                            end

                            if (current_y - last_operate_y_7 > 0 && last_operate_y_7 != 8'd241 && area_7 < `param_min_area)
                            begin
                                x_min_in_line_7 <= 9'd321;
                                x_max_in_line_7 <= 9'd0;
                                last_operate_y_7 <= 8'd241;
                                x_min_7 <= 9'd321;
                                x_max_7 <= 9'd0;
                                y_min_7 <= 8'd241;
                                y_max_7 <= 8'd0;
                                area_7 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_7 <= x_min_in_line_current_7;
                                x_max_in_line_7 <= x_max_in_line_current_7;
                            end

                            if (current_y - last_operate_y_6 > 0 && last_operate_y_6 != 8'd241 && area_6 < `param_min_area)
                            begin
                                x_min_in_line_6 <= 9'd321;
                                x_max_in_line_6 <= 9'd0;
                                last_operate_y_6 <= 9'd321;
                                x_min_6 <= 9'd321;
                                x_max_6 <= 9'd0;
                                y_min_6 <= 8'd241;
                                y_max_6 <= 8'd0;
                                area_6 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_6 <= x_min_in_line_current_6;
                                x_max_in_line_6 <= x_max_in_line_current_6;
                            end

                            if (current_y - last_operate_y_5 > 0 && last_operate_y_5 != 8'd241 && area_5 < `param_min_area)
                            begin
                                x_min_in_line_5 <= 9'd321;
                                x_max_in_line_5 <= 9'd0;
                                last_operate_y_5 <= 9'd321;
                                x_min_5 <= 9'd321;
                                x_max_5 <= 9'd0;
                                y_min_5 <= 8'd241;
                                y_max_5 <= 8'd0;
                                area_5 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_5 <= x_min_in_line_current_5;
                                x_max_in_line_5 <= x_max_in_line_current_5;
                            end

                            if (current_y - last_operate_y_4 > 0 && last_operate_y_4 != 8'd241 && area_4 < `param_min_area)
                            begin
                                x_min_in_line_4 <= 9'd321;
                                x_max_in_line_4 <= 9'd0;
                                last_operate_y_4 <= 9'd321;
                                x_min_4 <= 9'd321;
                                x_max_4 <= 9'd0;
                                y_min_4 <= 8'd241;
                                y_max_4 <= 8'd0;
                                area_4 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_4 <= x_min_in_line_current_4;
                                x_max_in_line_4 <= x_max_in_line_current_4;
                            end

                            if (current_y - last_operate_y_3 > 0 && last_operate_y_3 != 8'd241 && area_3 < `param_min_area)
                            begin
                                x_min_in_line_3 <= 9'd321;
                                x_max_in_line_3 <= 9'd0;
                                last_operate_y_3 <= 9'd321;
                                x_min_3 <= 9'd321;
                                x_max_3 <= 9'd0;
                                y_min_3 <= 8'd241;
                                y_max_3 <= 8'd0;
                                area_3 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_3 <= x_min_in_line_current_3;
                                x_max_in_line_3 <= x_max_in_line_current_3;
                            end

                            if (current_y - last_operate_y_2 > 0 && last_operate_y_2 != 8'd241 && area_2 < `param_min_area)
                            begin
                                x_min_in_line_2 <= 9'd321;
                                x_max_in_line_2 <= 9'd0;
                                last_operate_y_2 <= 9'd321;
                                x_min_2 <= 9'd321;
                                x_max_2 <= 9'd0;
                                y_min_2 <= 8'd241;
                                y_max_2 <= 8'd0;
                                area_2 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_2 <= x_min_in_line_current_2;
                                x_max_in_line_2 <= x_max_in_line_current_2;
                            end

                            if (current_y - last_operate_y_1 > 0 && last_operate_y_1 != 8'd241 && area_1 < `param_min_area)
                            begin
                                x_min_in_line_1 <= 9'd321;
                                x_max_in_line_1 <= 9'd0;
                                last_operate_y_1 <= 9'd321;
                                x_min_1 <= 9'd321;
                                x_max_1 <= 9'd0;
                                y_min_1 <= 8'd241;
                                y_max_1 <= 8'd0;
                                area_1 <= 11'd0;
                            end
                            else
                            begin
                                x_min_in_line_1 <= x_min_in_line_current_1;
                                x_max_in_line_1 <= x_max_in_line_current_1;
                            end

                        end
                    end
                    else
                    begin
                        current_x <= current_x + 9'd1;
                    end
                end
            end

            if (data_ack)
            begin
                data_last <= data;
                ready_for_req <= 1'b1;
                data_req <= 1'b0;
                if (data && !data_last)
                begin
                    process_x_min <= current_x;
                    process_x_max <= current_x;
                end
                else if (data) // 此像素为有效像素
                begin
                    if (current_x < process_x_min)
                    begin
                        process_x_min <= current_x;
                    end
                    if (current_x > process_x_max)
                    begin
                        process_x_max <= current_x;
                    end
                end
                else if (!data && data_last) // 此像素之前为有效像素，现在为无效像素，开始处理
                begin
                    if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_1 && (process_x_max + process_x_min ) /2 <= x_max_in_line_1) && ((current_y == last_operate_y_1 + 1) || current_y == last_operate_y_1))|| (last_operate_y_1 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_1)
                        begin
                            x_min_in_line_current_1 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_1)
                        begin
                            x_max_in_line_current_1 <= process_x_max;
                        end

                        if (process_x_min < x_min_1)
                        begin
                            x_min_1 <= process_x_min;
                        end
                        if (process_x_max > x_max_1)
                        begin
                            x_max_1 <= process_x_max;
                        end
                        if (current_y < y_min_1)
                        begin
                            y_min_1 <= current_y;
                        end
                        if (current_y > y_max_1)
                        begin
                            y_max_1 <= current_y;
                        end

                        last_operate_y_1 <= current_y;
                        area_1 <= area_1 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_2 && (process_x_max + process_x_min ) /2 <= x_max_in_line_2) && ((current_y == last_operate_y_2 + 1) || current_y == last_operate_y_2))|| (last_operate_y_2 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_2)
                        begin
                            x_min_in_line_current_2 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_1)
                        begin
                            x_max_in_line_current_1 <= process_x_max;
                        end
                        
                        
                        if (process_x_min < x_min_2)
                        begin
                            x_min_2 <= process_x_min;
                        end
                        if (process_x_max > x_max_2)
                        begin
                            x_max_2 <= process_x_max;
                        end
                        if (current_y < y_min_2)
                        begin
                            y_min_2 <= current_y;
                        end
                        if (current_y > y_max_2)
                        begin
                            y_max_2 <= current_y;
                        end

                        last_operate_y_2 <= current_y;
                        area_2 <= area_2 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_3 && (process_x_max + process_x_min ) /2 <= x_max_in_line_3) && ((current_y == last_operate_y_3 + 1) || current_y == last_operate_y_3))|| (last_operate_y_3 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_3)
                        begin
                            x_min_in_line_current_3 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_3)
                        begin
                            x_max_in_line_current_3 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_3)
                        begin
                            x_min_3 <= process_x_min;
                        end
                        if (process_x_max > x_max_3)
                        begin
                            x_max_3 <= process_x_max;
                        end
                        if (current_y < y_min_3)
                        begin
                            y_min_3 <= current_y;
                        end
                        if (current_y > y_max_3)
                        begin
                            y_max_3 <= current_y;
                        end


                        last_operate_y_3 <= current_y;
                        area_3 <= area_3 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_4 && (process_x_max + process_x_min ) /2 <= x_max_in_line_4) && ((current_y == last_operate_y_4 + 1) || current_y == last_operate_y_4))|| (last_operate_y_4 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_4)
                        begin
                            x_min_in_line_current_4 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_4)
                        begin
                            x_max_in_line_current_4 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_4)
                        begin
                            x_min_4 <= process_x_min;
                        end
                        if (process_x_max > x_max_4)
                        begin
                            x_max_4 <= process_x_max;
                        end
                        if (current_y < y_min_4)
                        begin
                            y_min_4 <= current_y;
                        end
                        if (current_y > y_max_4)
                        begin
                            y_max_4 <= current_y;
                        end


                        last_operate_y_4 <= current_y;
                        area_4 <= area_4 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_5 && (process_x_max + process_x_min ) /2 <= x_max_in_line_5) && ((current_y == last_operate_y_5 + 1) || current_y == last_operate_y_5 ))|| (last_operate_y_5 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_5)
                        begin
                            x_min_in_line_current_5 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_5)
                        begin
                            x_max_in_line_current_5 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_5)
                        begin
                            x_min_5 <= process_x_min;
                        end
                        if (process_x_max > x_max_5)
                        begin
                            x_max_5 <= process_x_max;
                        end
                        if (current_y < y_min_5)
                        begin
                            y_min_5 <= current_y;
                        end
                        if (current_y > y_max_5)
                        begin
                            y_max_5 <= current_y;
                        end


                        last_operate_y_5 <= current_y;
                        area_5 <= area_5 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_6 && (process_x_max + process_x_min ) /2 <= x_max_in_line_6) && ((current_y == last_operate_y_6 + 1) || current_y == last_operate_y_6  ))|| (last_operate_y_6 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_6)
                        begin
                            x_min_in_line_current_6 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_6)
                        begin
                            x_max_in_line_current_6 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_6)
                        begin
                            x_min_6 <= process_x_min;
                        end
                        if (process_x_max > x_max_6)
                        begin
                            x_max_6 <= process_x_max;
                        end
                        if (current_y < y_min_6)
                        begin
                            y_min_6 <= current_y;
                        end
                        if (current_y > y_max_6)
                        begin
                            y_max_6 <= current_y;
                        end


                        last_operate_y_6 <= current_y;
                        area_6 <= area_6 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_7 && (process_x_max + process_x_min ) /2 <= x_max_in_line_7) && ((current_y == last_operate_y_7 + 1) || current_y == last_operate_y_7 ))|| (last_operate_y_7 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_7)
                        begin
                            x_min_in_line_current_7 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_7)
                        begin
                            x_max_in_line_current_7 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_7)
                        begin
                            x_min_7 <= process_x_min;
                        end
                        if (process_x_max > x_max_7)
                        begin
                            x_max_7 <= process_x_max;
                        end
                        if (current_y < y_min_7)
                        begin
                            y_min_7 <= current_y;
                        end
                        if (current_y > y_max_7)
                        begin
                            y_max_7 <= current_y;
                        end


                        last_operate_y_7 <= current_y;
                        area_7 <= area_7 + (process_x_max - process_x_min + 1);
                    end

                    else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_8 && (process_x_max + process_x_min ) /2 <= x_max_in_line_8) && ((current_y == last_operate_y_8 + 1) || current_y == last_operate_y_8 ))|| (last_operate_y_8 == 8'd241 && !could_merge))
                    begin
                        if (process_x_min < x_min_in_line_current_8)
                        begin
                            x_min_in_line_current_8 <= process_x_min;
                        end
                        if (process_x_max > x_max_in_line_current_8)
                        begin
                            x_max_in_line_current_8 <= process_x_max;
                        end

                        
                        if (process_x_min < x_min_8)
                        begin
                            x_min_8 <= process_x_min;
                        end
                        if (process_x_max > x_max_8)
                        begin
                            x_max_8 <= process_x_max;
                        end
                        if (current_y < y_min_8)
                        begin
                            y_min_8 <= current_y;
                        end
                        if (current_y > y_max_8)
                        begin
                            y_max_8 <= current_y;
                        end


                        last_operate_y_8 <= current_y;
                        area_8 <= area_8 + (process_x_max - process_x_min + 1);
                    end

                    // else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_9 && (process_x_max + process_x_min ) /2 <= x_max_in_line_9) && ((current_y == last_operate_y_9 + 1)||current_y == last_operate_y_9 ) )|| (last_operate_y_9 == 8'd241 && !could_merge))
                    // begin
                    //     if (process_x_min < x_min_in_line_current_9)
                    //     begin
                    //         x_min_in_line_current_9 <= process_x_min;
                    //     end
                    //     if (process_x_max > x_max_in_line_current_9)
                    //     begin
                    //         x_max_in_line_current_9 <= process_x_max;
                    //     end

                        
                    //     if (process_x_min < x_min_9)
                    //     begin
                    //         x_min_9 <= process_x_min;
                    //     end
                    //     if (process_x_max > x_max_9)
                    //     begin
                    //         x_max_9 <= process_x_max;
                    //     end
                    //     if (current_y < y_min_9)
                    //     begin
                    //         y_min_9 <= current_y;
                    //     end
                    //     if (current_y > y_max_9)
                    //     begin
                    //         y_max_9 <= current_y;
                    //     end


                    //     last_operate_y_9 <= current_y;
                    //     area_9 <= area_9 + (process_x_max - process_x_min + 1);
                    // end

                    // else if ((((process_x_max + process_x_min ) / 2 >= x_min_in_line_10 && (process_x_max + process_x_min ) /2 <= x_max_in_line_10) && ((current_y == last_operate_y_10 + 1)||current_y == last_operate_y_10 ))|| (last_operate_y_10 == 8'd241 && !could_merge))
                    // begin
                    //     if (process_x_min < x_min_in_line_current_10)
                    //     begin
                    //         x_min_in_line_current_10 <= process_x_min;
                    //     end
                    //     if (process_x_max > x_max_in_line_current_10)
                    //     begin
                    //         x_max_in_line_current_10 <= process_x_max;
                    //     end

                        
                    //     if (process_x_min < x_min_10)
                    //     begin
                    //         x_min_10 <= process_x_min;
                    //     end
                    //     if (process_x_max > x_max_10)
                    //     begin
                    //         x_max_10 <= process_x_max;
                    //     end
                    //     if (current_y < y_min_10)
                    //     begin
                    //         y_min_10 <= current_y;
                    //     end
                    //     if (current_y > y_max_10)
                    //     begin
                    //         y_max_10 <= current_y;
                    //     end


                    //     last_operate_y_10 <= current_y;
                    //     area_10 <= area_10 + (process_x_max - process_x_min + 1);
                    // end   
                end
            end 
        end
    end
end

reg [5:0] search_index;
reg [10:0] max_area;
reg [10:0] min_area;

always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        hexagon_x <= 9'd0;
        hexagon_y <= 8'd0;
        circle_x <= 9'd0;
        circle_y <= 8'd0;
        square_x <= 9'd0;
        square_y <= 8'd0;
        analysis_done <= 1'b0;
        search_index <= 6'd0;
        max_area <= 11'd0;
        min_area <= 11'd2040;

    end
    else
    begin
        if (capture_finished)  // 已完成图像遍历，开始分析形状
        begin
            case (search_index)
            6'd0 : begin
                search_index <= search_index + 6'd1;
                if (area_1 > max_area && area_1 > `param_min_area)
                begin
                    max_area <= area_1;
                    square_x <= x_min_1 + (x_max_1 - x_min_1) / 2;
                    square_y <= y_min_1 + (y_max_1 - y_min_1) / 2;
                    square_right <= x_max_1;
                    square_left  <= x_min_1;
                    if ((x_max_1 - x_max_in_line_1) > (x_min_in_line_1 - x_min_1))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end

                end
            end
            6'd1 : begin
                search_index <= search_index + 6'd1;
                if (area_2 > max_area && area_2 > `param_min_area)
                begin
                    max_area <= area_2;
                    square_x <= x_min_2 + (x_max_2 - x_min_2) / 2;
                    square_y <= y_min_2 + (y_max_2 - y_min_2) / 2;
                    square_right <= x_max_2;
                    square_left  <= x_min_2;
                    if ((x_max_2 - x_max_in_line_2) > (x_min_in_line_2 - x_min_2))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd2 : begin
                search_index <= search_index + 6'd1;
                if (area_3 > max_area && area_3 > `param_min_area)
                begin
                    max_area <= area_3;
                    square_x <= x_min_3 + (x_max_3 - x_min_3) / 2;
                    square_y <= y_min_3 + (y_max_3 - y_min_3) / 2;
                    square_right <= x_max_3;
                    square_left  <= x_min_3;
                    if ((x_max_3 - x_max_in_line_3) > (x_min_in_line_3 - x_min_3))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end

                end
            end
            6'd3 : begin
                search_index <= search_index + 6'd1;
                if (area_4 > max_area && area_4 > `param_min_area)
                begin
                    max_area <= area_4;
                    square_x <= x_min_4 + (x_max_4 - x_min_4) / 2;
                    square_y <= y_min_4 + (y_max_4 - y_min_4) / 2;
                    square_right <= x_max_4;
                    square_left  <= x_min_4;
                    if ((x_max_4 - x_max_in_line_4) > (x_min_in_line_4 - x_min_4))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd4 : begin
                search_index <= search_index + 6'd1;
                if (area_5 > max_area && area_5 > `param_min_area)
                begin
                    max_area <= area_5;
                    square_x <= x_min_5 + (x_max_5 - x_min_5) / 2;
                    square_y <= y_min_5 + (y_max_5 - y_min_5) / 2;
                    square_right <= x_max_5;
                    square_left  <= x_min_5;
                    if ((x_max_5 - x_max_in_line_5) > (x_min_in_line_5 - x_min_5))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd5 : begin
                search_index <= search_index + 6'd1;
                if (area_6 > max_area && area_6 > `param_min_area)
                begin
                    max_area <= area_6;
                    square_x <= x_min_6 + (x_max_6 - x_min_6) / 2;
                    square_y <= y_min_6 + (y_max_6 - y_min_6) / 2;
                    square_right <= x_max_6;
                    square_left  <= x_min_6;
                    if ((x_max_6 - x_max_in_line_6) > (x_min_in_line_6 - x_min_6))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd6 : begin
                search_index <= search_index + 6'd1;
                if (area_7 > max_area && area_7 > `param_min_area)
                begin
                    max_area <= area_7;
                    square_x <= x_min_7 + (x_max_7 - x_min_7) / 2;
                    square_y <= y_min_7 + (y_max_7 - y_min_7) / 2;
                    square_right <= x_max_7;
                    square_left  <= x_min_7;
                    if ((x_max_7 - x_max_in_line_7) > (x_min_in_line_7 - x_min_7))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd7 : begin
                search_index <= search_index + 6'd1;
                if (area_8 > max_area && area_8 > `param_min_area)
                begin
                    max_area <= area_8;
                    square_x <= x_min_8 + (x_max_8 - x_min_8) / 2;
                    square_y <= y_min_8 + (y_max_8 - y_min_8) / 2;
                    square_right <= x_max_8;
                    square_left  <= x_min_8;
                    if ((x_max_8 - x_max_in_line_8) > (x_min_in_line_8 - x_min_8))
                    begin
                        left_or_right <= 1'b0; //需要往左旋转
                    end
                    else
                    begin
                        left_or_right <= 1'b1; //需要往右旋转
                    end
                end
            end
            6'd8 : begin
                search_index <= search_index + 6'd1;
                // if (area_9 > max_area && area_9 > `param_min_area)
                // begin
                //     max_area <= area_9;
                //     square_x <= x_min_9 + (x_max_9 - x_min_9) / 2;
                //     square_y <= y_min_9 + (y_max_9 - y_min_9) / 2;
                //     square_right <= x_max_9;
                //     square_left  <= x_min_9;
                //     if ((x_max_9 - x_max_in_line_9) > (x_min_in_line_9 - x_min_9))
                //     begin
                //         left_or_right <= 1'b0; //需要往左旋转
                //     end
                //     else
                //     begin
                //         left_or_right <= 1'b1; //需要往右旋转
                //     end
                // end
            end
            6'd9 : begin
                search_index <= search_index + 6'd1;
                // if (area_10 > max_area  && area_10 > `param_min_area)
                // begin
                //     max_area <= area_10;
                //     square_x <= x_min_10 + (x_max_10 - x_min_10) / 2;
                //     square_y <= y_min_10 + (y_max_10 - y_min_10) / 2;
                // end
            end
            6'd10 : begin
                search_index <= search_index + 6'd1;
                if (area_1 < min_area && area_1 > `param_min_area)
                begin
                    min_area <= area_1;
                    hexagon_x <= x_min_1 + (x_max_1 - x_min_1) / 2;
                    hexagon_y <= y_min_1 + (y_max_1 - y_min_1) / 2;
                end
            end
            6'd11 : begin
                search_index <= search_index + 6'd1;
                if (area_2 < min_area && area_2 > `param_min_area)
                begin
                    min_area <= area_2;
                    hexagon_x <= x_min_2 + (x_max_2 - x_min_2) / 2;
                    hexagon_y <= y_min_2 + (y_max_2 - y_min_2) / 2;
                end
            end
            6'd12 : begin
                search_index <= search_index + 6'd1;
                if (area_3 < min_area && area_3 > `param_min_area)
                begin
                    min_area <= area_3;
                    hexagon_x <= x_min_3 + (x_max_3 - x_min_3) / 2;
                    hexagon_y <= y_min_3 + (y_max_3 - y_min_3) / 2;
                end
            end
            6'd13 : begin
                search_index <= search_index + 6'd1;
                if (area_4 < min_area && area_4 > `param_min_area)
                begin
                    min_area <= area_4;
                    hexagon_x <= x_min_4 + (x_max_4 - x_min_4) / 2;
                    hexagon_y <= y_min_4 + (y_max_4 - y_min_4) / 2;
                end
            end
            6'd14 : begin
                search_index <= search_index + 6'd1;
                if (area_5 < min_area && area_5 > `param_min_area)
                begin
                    min_area <= area_5;
                    hexagon_x <= x_min_5 + (x_max_5 - x_min_5) / 2;
                    hexagon_y <= y_min_5 + (y_max_5 - y_min_5) / 2;
                end
            end
            6'd15 : begin
                search_index <= search_index + 6'd1;
                if (area_6 < min_area && area_6 > `param_min_area)
                begin
                    min_area <= area_6;
                    hexagon_x <= x_min_6 + (x_max_6 - x_min_6) / 2;
                    hexagon_y <= y_min_6 + (y_max_6 - y_min_6) / 2;
                end
            end
            6'd16 : begin
                search_index <= search_index + 6'd1;
                if (area_7 < min_area && area_7 > `param_min_area)
                begin
                    min_area <= area_7;
                    hexagon_x <= x_min_7 + (x_max_7 - x_min_7) / 2;
                    hexagon_y <= y_min_7 + (y_max_7 - y_min_7) / 2;
                end
            end
            6'd17 : begin
                search_index <= search_index + 6'd1;
                if (area_8 < min_area && area_8 > `param_min_area)
                begin
                    min_area <= area_8;
                    hexagon_x <= x_min_8 + (x_max_8 - x_min_8) / 2;
                    hexagon_y <= y_min_8 + (y_max_8 - y_min_8) / 2;
                end
            end
            6'd18 : begin
                search_index <= search_index + 6'd1;
                // if (area_9 < min_area && area_9 > `param_min_area)
                // begin
                //     min_area <= area_9;
                //     hexagon_x <= x_min_9 + (x_max_9 - x_min_9) / 2;
                //     hexagon_y <= y_min_9 + (y_max_9 - y_min_9) / 2;
                // end
            end
            6'd19 : begin
                search_index <= search_index + 6'd1;
                // if (area_10 < min_area && area_10 > `param_min_area)
                // begin
                //     min_area <= area_10;
                //     hexagon_x <= x_min_10 + (x_max_10 - x_min_10) / 2;
                //     hexagon_y <= y_min_10 + (y_max_10 - y_min_10) / 2;
                // end
            end
            6'd20 : begin
                search_index <= search_index + 6'd1;
                if (area_1 < max_area && area_1 > min_area)
                begin
                    circle_x <= x_min_1 + (x_max_1 - x_min_1) / 2;
                    circle_y <= y_min_1 + (y_max_1 - y_min_1) / 2;
                end
            end
            6'd21 : begin
                search_index <= search_index + 6'd1;
                if (area_2 < max_area && area_2 > min_area)
                begin
                    circle_x <= x_min_2 + (x_max_2 - x_min_2) / 2;
                    circle_y <= y_min_2 + (y_max_2 - y_min_2) / 2;
                end
            end
            6'd22 : begin
                search_index <= search_index + 6'd1;
                if (area_3 < max_area && area_3 > min_area)
                begin
                    circle_x <= x_min_3 + (x_max_3 - x_min_3) / 2;
                    circle_y <= y_min_3 + (y_max_3 - y_min_3) / 2;
                end
            end
            6'd23 : begin
                search_index <= search_index + 6'd1;
                if (area_4 < max_area && area_4 > min_area)
                begin
                    circle_x <= x_min_4 + (x_max_4 - x_min_4) / 2;
                    circle_y <= y_min_4 + (y_max_4 - y_min_4) / 2;
                end
            end
            6'd24 : begin
                search_index <= search_index + 6'd1;
                if (area_5 < max_area && area_5 > min_area)
                begin
                    circle_x <= x_min_5 + (x_max_5 - x_min_5) / 2;
                    circle_y <= y_min_5 + (y_max_5 - y_min_5) / 2;
                end
            end
            6'd25 : begin
                search_index <= search_index + 6'd1;
                if (area_6 < max_area && area_6 > min_area)
                begin
                    circle_x <= x_min_6 + (x_max_6 - x_min_6) / 2;
                    circle_y <= y_min_6 + (y_max_6 - y_min_6) / 2;
                end
            end
            6'd26 : begin
                search_index <= search_index + 6'd1;
                if (area_7 < max_area && area_7 > min_area)
                begin
                    circle_x <= x_min_7 + (x_max_7 - x_min_7) / 2;
                    circle_y <= y_min_7 + (y_max_7 - y_min_7) / 2;
                end
            end
            6'd27 : begin
                search_index <= search_index + 6'd1;
                if (area_8 < max_area && area_8 > min_area)
                begin
                    circle_x <= x_min_8 + (x_max_8 - x_min_8) / 2;
                    circle_y <= y_min_8 + (y_max_8 - y_min_8) / 2;
                end
            end
            6'd28 : begin
                search_index <= search_index + 6'd1;
                // if (area_9 < max_area && area_9 > min_area)
                // begin
                //     circle_x <= x_min_9 + (x_max_9 - x_min_9) / 2;
                //     circle_y <= y_min_9 + (y_max_9 - y_min_9) / 2;
                // end
            end
            6'd29 : begin
                search_index <= search_index + 6'd1;
                // if (area_10 < max_area && area_10 > min_area)
                // begin
                //     circle_x <= x_min_10 + (x_max_10 - x_min_10) / 2;
                //     circle_y <= y_min_10 + (y_max_10 - y_min_10) / 2;
                // end
            end
            6'd30 : begin
                analysis_done <= 1'b1;
            end
            endcase
        end
    end
end

endmodule