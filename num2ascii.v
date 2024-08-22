module num2ascii(
    input clk,
    input rst_n,
    input [11:0] angle_input,
    output reg [15:0] angle_output
);

reg [11:0] angle_count;
reg [2:0] single_num_index; // 3 down to 0
reg [3:0] single_num_count;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        angle_count <= 0;
        single_num_index <= 3'd3;
        angle_output <= 0;
        single_num_count <=0;
    end
    else
    begin
        case(single_num_index)
        3'd3: // 千位
            begin
                if (angle_count + 12'd1000 > angle_input)
                begin
                    single_num_index <= 3'd2;
                    single_num_count <= 0;
                    angle_output[15:12] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd1000;
                end
            end
        3'd2: // 百位
            begin
                if (angle_count + 12'd100 > angle_input)
                begin
                    single_num_index <= 3'd1;
                    single_num_count <= 0;
                    angle_output[11:8] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd100;
                end
            end
        3'd1: // 十位
            begin
                if (angle_count + 12'd10 > angle_input)
                begin
                    single_num_index <= 3'd0;
                    single_num_count <= 0;
                    angle_output[7:4] <= single_num_count + 4'd48;
                end
                else
                begin
                    single_num_count <= single_num_count +1 ;
                    angle_count <= angle_count + 12'd10;
                end
            end
        3'd0: // 个位
            begin
                if (angle_count + 12'd1 > angle_input)
                begin
                    single_num_index <= 3'd4;
                    single_num_count <= 0;
                    angle_output[3:0] <= single_num_count + 4'd48;
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