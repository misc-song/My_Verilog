`timescale 1ns / 1ps
// `include "key_filter.v"
module key_filter_tb();

//================ 参数定义 ================
localparam CLK_PERIOD = 20;          // 50MHz时钟，周期20ns
localparam DEBOUNCE_MS = 20;         // 消抖时间20ms
localparam CLK_FREQ = 50_000_000;    // 与模块参数一致

//================ 信号声明 ================
reg clk;
reg rst_n;
reg key_in;
wire key_out;
wire key_pressed;

// 实例化待测模块（DUT）
key_filter #(
    .CLK_FREQ   (CLK_FREQ),
    .DEBOUNCE_MS(DEBOUNCE_MS)
) uut (
    .clk        (clk),
    .rst_n      (rst_n),
    .key_in     (key_in),
    .key_out    (key_out),
    .key_pressed(key_pressed)
);

//================ 时钟生成 ================
always # (CLK_PERIOD/2) clk = ~clk;

//================ 复位与激励产生 ================
initial begin
    // 初始化
    clk = 0;
    rst_n = 0;
    key_in = 1'b1;  // 按键默认释放（高电平）

    // 复位释放
    #100;
    rst_n = 1;
    #200;  // 等待稳定

    // ------ 第一次按键：正常按下并释放（带抖动） ------
    // 1. 按下开始，先出现抖动
    # (1_000_000);  // 等待1ms
    key_in = 1'b0;  // 第一次低电平
    # 5_000_000;    // 抖动：5ms后变高
    key_in = 1'b1;
    # 2_000_000;    // 抖动：2ms后变低
    key_in = 1'b0;
    # 1_000_000;    // 抖动：1ms后变高
    key_in = 1'b1;
    # 3_000_000;    // 抖动：3ms后变低
    key_in = 1'b0;

    // 2. 真正稳定按下，持续 30ms（超过20ms消抖时间）
    # (30_000_000);

    // 3. 释放，先抖动
    key_in = 1'b1;   // 第一次高电平
    # 4_000_000;     // 抖动：4ms后变低
    key_in = 1'b0;
    # 2_000_000;     // 抖动：2ms后变高
    key_in = 1'b1;
    # 3_000_000;     // 抖动：3ms后变低
    key_in = 1'b0;
    # 1_000_000;     // 抖动：1ms后变高
    key_in = 1'b1;

    // 4. 稳定释放，保持高电平
    # (30_000_000);

    // ------ 第二次按键：快速连续按下（用于测试脉冲） ------
    // 稳定按下 10ms（小于消抖时间，应无效）
    # 1_000_000;
    key_in = 1'b0;
    # 10_000_000;    // 持续10ms，小于20ms，预期不产生 key_pressed
    key_in = 1'b1;
    # 5_000_000;

    // 稳定按下 30ms（有效）
    key_in = 1'b0;
    # 30_000_000;    // 持续30ms，应产生有效按下脉冲
    key_in = 1'b1;
    # 20_000_000;

    // 仿真结束
    $display("Simulation finished.");
    $finish;
end

//================ 监控输出（可选） ================
// 打印关键时间点的状态变化
always @(posedge clk) begin
    if (key_pressed) begin
        $display("[%t] key_pressed = 1, key_out = %b", $time, key_out);
    end
    if (key_out !== uut.key_out) begin  // 也可以观察内部状态变化
        // 不强制，仅用于调试
    end
end

// 也可以使用波形查看，但此处不做强制

endmodule