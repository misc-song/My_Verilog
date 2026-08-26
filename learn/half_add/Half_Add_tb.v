`timescale 10ns/1ns
// `include "Half_Add.v"    //在testbench中，不需要include
module Half_Add_tb();
// `include "Half_Add.v"   //include写在模块内部 导致module 嵌套 模块不能嵌套定义
reg in1,in2;     //inital 中产生激励信号时，需要用reg类型
wire o1,o2;

Half_Add add(.A(in1),.B(in2),.O(o1),.C(o2));

initial begin
    $dumpfile("Half_Add.vcd");
    $dumpvars(0,Half_Add_tb);
end

initial begin
    in1 = 0; in2 =0;
    # 100
    in1 = 0; in2 =1;
    # 100
    in1 = 1; in2 =0;
    # 100
    in1 = 1; in2 =1;
    # 100
    $finish;
end

endmodule