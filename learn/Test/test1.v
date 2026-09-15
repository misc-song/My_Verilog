module test1(
  input  [31:0] x,
  output [31:0] y
);
    integer i;
    reg [1:0] counter;
    reg [31:0] res;
    always@(*) begin

        res = x;
        counter = 0;
        for(i=0;i<32;i=i+1) begin
            if(counter !=2)begin
                if(res[i] == 1)begin
                    res[i] = 0;
                    counter = counter +1;
                end
            end
        end
    end

    assign y = res;
  
endmodule