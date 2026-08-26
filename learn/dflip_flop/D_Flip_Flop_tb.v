`timescale 10ns/1ns
// `include "D_Flip_Flop.v"
module D_Flip_Flop_tb;

reg clk;
reg rst;
reg d;
wire q;

D_Flip_Flop dut(
	.clk(clk),
	.reset(rst),
	.in(d),
	.out(q)
);
// in,clk,reset,out
initial begin
	clk = 0;
	rst = 0;
	d = 0;
end
initial begin
    $dumpfile("D_Flip_Flop_tb.vcd");
    $dumpvars(0,D_Flip_Flop_tb);
end

always begin
    #10 rst <= 0; d<=0;
    #10 rst <= 0; d<=1;
    #10 rst <= 1; d<=0;
    #10 rst <= 1; d<=1;
    #10
    $finish;
end

always #5 clk = ~clk;

endmodule