`timescale 1ns/1ns
// `include "Counter1.v"
module Counter1_tb();
    reg clk;
    reg rstn;
    wire [4:0] onesPlace;
    wire [4:0] tensPlace;
    wire [4:0] hundredsPlace;
    wire en;

Counter1 dut(clk,rstn,onesPlace,tensPlace,hundredsPlace,en);
always #1 clk <=~clk;
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,Counter1_tb);
end
initial begin
    clk = 0;
    rstn = 0;
    #10 
    rstn = 1;

    # 110
    $finish;
end




endmodule