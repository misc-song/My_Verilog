module Counter1(
    input clk,
    input rstn,
    output reg [4:0] onesPlace,
    output reg [4:0] tensPlace,
    output reg [4:0] hundredsPlace,
    output reg en
);

always @(posedge clk or negedge rstn) begin
    if(rstn == 0) begin
        onesPlace <= 0;
    end
    else if(onesPlace == 9) begin
        onesPlace <=0;
    end
    else
        onesPlace <= onesPlace + 1;
end

always @(posedge clk or negedge rstn) begin
     if(rstn == 0)begin
        tensPlace <= 0;
    end
    else if(onesPlace == 4'd9) begin
        tensPlace <= 0;
        tensPlace <= tensPlace + 1;
    end
    else 
        tensPlace <= tensPlace;
end
always @(posedge clk or negedge rstn) begin
     if(rstn == 0)begin
        hundredsPlace <= 0;
    end
    else if(tensPlace == 4'd9 && onesPlace == 4'd9)
        hundredsPlace <= hundredsPlace +1'b1;
    else 
       hundredsPlace <= hundredsPlace;
end
always @(posedge clk or negedge rstn) begin
     if(rstn == 0)begin
        en <= 0;
    end
    else if(tensPlace == 4'd9 && onesPlace == 4'd9 && hundredsPlace == 4'd9) begin
        hundredsPlace <= 0;
        en <= 1;
    end
    else 
       en <= en;
end


endmodule



