module test_mem() ;
    reg [8-1:0] mem0 [8-1:0]; //定义8x8的存储器
    reg [8-1:0] mem1 [8-1:0]; //定义8x8的存储器
    integer count ;

    initial begin

        $readmemb("initb.dat",mem0);
        $readmemh("inith.dat",mem1);
        for(count=0;count<8;count++) begin
            $display("mem0[%d] = %b",count,mem0[count]);
            $display("mem1[%d] = %h",count,mem1[count]);
        end

    end


    
endmodule