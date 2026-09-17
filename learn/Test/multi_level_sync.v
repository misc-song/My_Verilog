module multi_level_sync(
    input clk,
    input in,
    input rst_n,
    output out
);
    reg q1,q2,q3;

    always@(posedge clk or negedge rst_n) begin
        if(rst_n ==0) begin
            q1 <= 0;
            q2 <= 0;
            q3 <= 0; 
        end
        else 
            q1<=in;  //第一级同步 抵抗亚稳态
            q2<=q1;  //第二级同步保持稳定
            q3<=q2;  //第三级 保持上一个信号稳定
    end

    assign out = q2^q3;  // 双边沿检测

    // assign rise_p  = q2 & (~q3);        //上升沿
    // assign fall_p  = (~q2) & q3;        //下降沿
    // assign both_p  = q2 ^ q3;           //双边沿，异或！！！



endmodule








