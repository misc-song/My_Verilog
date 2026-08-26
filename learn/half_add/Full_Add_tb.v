`timescale 10ns/1ns
// `include "Full_Add.v"
module Full_Add_tb();
    reg a,b,cin;
    wire sum,cout;
    Full_Add uut(a,b,cin,sum,cout);

    initial begin
        $dumpfile("Full_Add.vcd");
        $dumpvars(0,Full_Add_tb);
    end

    initial begin
        a=0;b=0;cin=0;
        #10 a=0;b=0;cin=1;
        #10 a=0;b=1;cin=0;
        #10 a=0;b=1;cin=1;
        #10 a=1;b=0;cin=0;
        #10 a=1;b=0;cin=1;
        #10 a=1;b=1;cin=0;
        #10 a=1;b=1;cin=1;
        #10 $finish;
    end
endmodule
