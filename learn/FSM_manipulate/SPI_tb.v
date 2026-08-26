`timescale 1ns/1ns

module SPI_tb();
reg clk;
reg rst;
reg en;
wire spi_clk;
wire cs;
wire out;

SPI dut(clk, rst, en, spi_clk, cs, out);
initial begin
	$dumpfile("SPI.vcd");
	$dumpvars(0,SPI_tb);
end

initial begin
	clk = 0;
	rst = 0;
	
	#10 rst = 1;
	en = 1;
    # 1000 $finish;
end
always #5 clk = ~clk;
endmodule
