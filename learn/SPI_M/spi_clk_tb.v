`timescale 1ns / 1ns
module spi_clk_tb;

reg clk;
reg rest;
wire spi_clk;

spi_clk dut(
	.sys_clk(clk),
	.reset_n(rest),
	.spi_clk(spi_clk)
);

initial begin
	$dumpfile("spi_clk_tb.vcd");
	$dumpvars(0, spi_clk_tb);
end

always #5 clk = ~clk;
initial begin
	clk = 0;
	rest = 0;
	# 100;
	rest = 1;
    # 1000;
    $finish;
end
endmodule



