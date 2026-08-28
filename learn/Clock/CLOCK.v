module CLOCK(
    input clk,
    input reset,
    output reg [5:0] HH, 
    output reg [5:0] MM, 
    output reg [5:0] SS,
    output reg en
);



always @(posedge clk) begin
    if(reset == 0) begin
        HH <= 0;
        MM <= 0;
        SS <= 0;
    end
    else begin
        SS <= SS + 1;
        if (SS == 59) begin
            SS <= 0;
            MM <= MM + 1;
            en <= 1;
            if (MM == 59) begin
                MM <= 0;
                HH <= HH + 1;
                if (HH == 23) begin
                    HH <= 0;
                end
            end
        end
        else
            en <= 0;
    end
end

endmodule