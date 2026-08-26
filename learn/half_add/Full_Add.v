`include "Half_Add.v"
//使用两个半加器实现全加器
module Full_Add(num1,num2,cin,sum,cout);

    input wire num1,num2,cin;      // 加数 被加数 上一个进位   input 后面不能跟reg
    output wire sum,cout;     // 和 进位


    wire sum1,cin1,cout1,cout2;

    Half_Add HA1(num1,num2,sum1,cout1);
    Half_Add HA2(sum1,cin,sum,cout2);

    assign cout = cout1 | cout2;

endmodule
