`timescale 1ns/1ps  // 时间单位是1ns 精度是1ps
module chip_74138_tb();
    reg reset;
    reg [2:0]in;
    wire [7:0]out;
    chip_74138 chip(reset,in,out);
    initial begin
        reset = 1'b1;
        #10 reset = 1'b0;
        in = 3'b000;
        #10 in = 3'b001;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b010;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b011;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b100;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b101;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b110;
        $monitor("in = %b, out = %b",in,out);
        #10 in = 3'b111;
        $monitor("in = %b, out = %b",in,out);
        #10
        $finish;
    end
endmodule;