module Half_Add(A,B,O,C);

    /*采用连续赋值的方式实现半加器*/
    input wire A,B;
    output wire O,C;
    assign O = A^B;     //assign 赋值时只能是wire类型   ^是异或 运算符
    assign C = A&B;
    // assign {C,O}    = A+B;  //{}是位拼接运算符 半加器的另一种实现方法

    /*采用always块实现半加器*/
    // input wire A,B;
    // output reg O,C;
    // always@(*) begin
    //     {C,O} = A+B;
    // end

endmodule