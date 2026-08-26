`timescale 1ps/1ps
module chip_74595_tb();
    reg in;
    reg clk;
    reg control;
    reg reset;
    wire [7:0] out;


    chip_74595 uut(
        .in(in),
        .clk(clk),
        .control(control),
        .reset(reset),
        .out(out)
    );

    initial begin
        forever #5 clk = ~clk; // 周期10ps
    end

    initial begin
        // 初始化输入值
        in = 0;
        clk = 0;
        control = 0;
        reset = 0;
    

        #10 reset = 1;
        // 给数据赋值
        #10 in = 1; 
        #10 in = 0; 
        #10 in = 1; 
        #10 in = 1; 
        #10 in = 0; 
        #10 in = 1; 
        #10 in = 0; 
        #10 in = 1; 
        // 输出数据
        #10 control = 1;  
        $monitor("outdata : %b", out);
        #20;
        $finish;

    end



endmodule

