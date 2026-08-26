`timescale  1ns/1ns
module Cnt_1s_tb;
reg clk;
reg rst;
wire [25:0] cnt;
wire led;
Cnt_1s dut(clk, rst, cnt,led);
initial begin
    $dumpfile("Cnt_1s.vcd");
    $dumpvars(0, Cnt_1s_tb);
end
initial begin
    clk = 0;
    rst = 1;
    
end

initial begin
    #10
    rst = 0;
    # 100
    $finish;
end
always #1 clk = ~clk;
endmodule