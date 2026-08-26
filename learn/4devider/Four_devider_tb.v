`timescale 1ns/1ns
// `include "Four_devider.v"
module Four_devider_tb();

reg clk,rst;
wire out;
Four_devider dut(clk,rst,out);
initial begin
    $dumpfile("Four_devider_tb.vcd");
    $dumpvars(0,dut);
end

initial begin
    clk = 0;
	rst = 1;
    # 10 rst = 0;
    # 500 $finish;
end
always #1 clk = ~clk;
endmodule
