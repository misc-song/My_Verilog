module top_module(
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n   
); 
// 请用户在下方编辑代码
	reg m1;
    reg m2;
    always@(*) begin       
        m1 = a&b;
        m2 = c&d;
        out = m1|m2;
        out_n = ~(m1|m2);
    end
  
//用户编辑到此为止
endmodule
