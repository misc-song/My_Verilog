`timescale 1ns/1ns

module CLOCK_tb();
reg clk;
reg rst;
wire [5:0] HH;
wire [5:0] MM;
wire [5:0] SS;
wire en;
CLOCK dut(clk, rst, HH, MM, SS,en);

initial begin
	$dumpfile("CLOCK.vcd");
	$dumpvars(0, CLOCK_tb);
end

initial begin
	clk = 0;
	rst = 0;
	#10 rst = 0;
	#10 rst = 1;
	# 100000 $finish;
end
always #5 clk = ~clk;
endmodule


