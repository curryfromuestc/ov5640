module angle_correction (
    input clk,
    input rst_n,
    input [11:0] source_angle,
    input [11:0] target_angle,
    input [8:0] x_left,
    input [8:0] x_right,
    input left_or_right,
    output reg [15:0] corrected_angle
);


reg [11:0] angle_diff;

reg [11:0] angle_diff_abs;

// covent source and dest angle from ascii to number
// wire [11:0] source_angle_conv;
// wire [11:0] target_angle_conv;
// assign source_angle_conv = (source_angle[15:12] - 48) * 1000 + (source_angle[11:8] - 48) * 100
//                              + (source_angle[7:4] - 48) * 10 + (source_angle[3:0] - 48);
// assign target_angle_conv = (target_angle[15:12] - 48) * 1000 + (target_angle[11:8] - 48) * 100
//                              + (target_angle[7:4] - 48) * 10 + (target_angle[3:0] - 48);

always @(*)
begin
    if (left_or_right == 1'b0)
        angle_diff <= 1500 - source_angle + target_angle - (x_right - x_left - 30)* 75;
    else
        angle_diff <= 1500 - source_angle + target_angle + (x_right - x_left - 30)* 75;
end

always @(*) begin
    if (angle_diff  > 12'd1999 + 1500)
        angle_diff_abs <= angle_diff - 12'd1999;
    else if (angle_diff > 12'd1333 + 1500)
        angle_diff_abs <= angle_diff - 12'd1333;
    else if (angle_diff > 12'd666+ 1500)
        angle_diff_abs <= angle_diff - 12'd666;
    else if (angle_diff < 1500 - 666)
        angle_diff_abs <= angle_diff + 12'd666;
    else if (angle_diff < 1500 - 1333)
        angle_diff_abs <= angle_diff + 12'd1333;
    else if (angle_diff < 1500 - 1999)
        angle_diff_abs <= angle_diff + 12'd1999;
    else
        angle_diff_abs <= angle_diff;
end



reg [11:0] angle_count;
reg [2:0] single_num_index; // 3 down to 0
reg [3:0] single_num_count;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        angle_count <= 0;
        single_num_index <= 3'd3;
        corrected_angle <= 0;
        single_num_count <=0;
    end
    else
    begin
        case(single_num_index)
        3'd3: // 千位
            begin
                if (angle_count + 12'd1000 > angle_diff_abs)
                begin
                    single_num_index <= 3'd2;
                    single_num_count <= 0;
                    corrected_angle[15:12] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd1000;
                end
            end
        3'd2: // 百位
            begin
                if (angle_count + 12'd100 > angle_diff_abs)
                begin
                    single_num_index <= 3'd1;
                    single_num_count <= 0;
                    corrected_angle[11:8] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd100;
                end
            end
        3'd1: // 十位
            begin
                if (angle_count + 12'd10 > angle_diff_abs)
                begin
                    single_num_index <= 3'd0;
                    single_num_count <= 0;
                    corrected_angle[7:4] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd10;
                end
            end
        3'd0: // 个位
            begin
                if (angle_count + 12'd1 > angle_diff_abs)
                begin
                    single_num_index <= 3'd4;
                    single_num_count <= 0;
                    corrected_angle[3:0] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd1;
                end
            end
        3'd4: // 结束
            begin
            end
        endcase
    end
end




endmodule