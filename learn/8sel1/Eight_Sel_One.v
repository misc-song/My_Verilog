module Eight_Sel_One(data, sel, y);

input [7:0] data;
input [2:0] sel;
output reg y;
always@(*) begin
    case(sel) 
        3'b000: y = data[0];
        3'b001: y = data[1];
        3'b010: y = data[2];
        3'b011: y = data[3];
        3'b100: y = data[4];
        3'b101: y = data[5];
        3'b110: y = data[6];
        3'b111: y = data[7];
    endcase
end

endmodule