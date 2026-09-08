//============================================================================
// 毫秒延时定时器
// clk=50MHz，1ms = 50000个时钟周期
// start：启动脉冲；delay_ms：需要延时多少ms；done：延时完成脉冲
//============================================================================
module ms_delay_timer(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        delay_start,  // 启动延时脉冲
    input  wire [7:0]  delay_ms,     // 延时毫秒数

    output wire        delay_done    // 延时完成标志
);

reg [23:0] delay_cnt;
reg        delay_active;

assign delay_done = !(delay_active || delay_start);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay_cnt    <= 24'd0;
        delay_active <= 1'b0;
    end else if(delay_start) begin
        delay_cnt    <= delay_ms * 24'd50000;
        delay_active <= 1'b1;
    end else if(delay_active) begin
        if(delay_cnt <= 24'd1) begin
            delay_active <= 1'b0;
        end else begin
            delay_cnt <= delay_cnt - 1'b1;
        end
    end
end

endmodule
