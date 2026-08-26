`timescale 1ns/1ns
module Flow_LED_tb();
reg clk;
reg rst;
wire [7:0] led;
Flow_LED dut(clk, rst, led);
initial begin
    $dumpfile("Flow_LED_tb.vcd");
    $dumpvars(0, dut);
end
initial begin
    clk = 0;
    rst = 0;
    #10 rst = 1;
    #10 rst = 0;
    #8000 $finish;
end
always #5 clk = ~clk;
endmodule