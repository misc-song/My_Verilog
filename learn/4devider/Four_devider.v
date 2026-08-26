// module Four_devider(clk,rst,clk_out);
//     input clk,rst;
//     output reg clk_out;
//     reg [1:0] count;
//     always@(posedge clk or posedge rst)
//     begin
//         if(rst == 1'b1) begin
//             count <= 2'b00;
//             clk_out <= 1'b0;
//         end
//         else if(count == 2'b01) begin
//             count <= 2'b00;
//         end
//         else
//             count <= count + 1'b1;
//     end

//    always@(posedge clk or posedge rst) begin
//       if(rst == 1'b1)
//        clk_out <= 1'b0;
//       else if(count == 2'b01)
//         clk_out <= ~clk_out;
//       else
//         clk_out <= clk_out;
//     end
    

//     // always@(posedge clk or posedge rst) begin
//     //   if(rst == 1'b1)
//     //    clk_out <= 1'b0;
//     //   else if(count == 2'b01)
//     //     clk_out <= 1'b1;
//     //   else
//     //     clk_out <= 1'b0;
//     // end
// endmodule

module Four_devider(clk,rst,clk_out);
    input clk,rst;
    output reg clk_out;
    reg [1:0] count;
    always@(posedge clk or posedge rst)
    begin
        if(rst == 1'b1) begin
            count <= 2'b00;
            clk_out <= 1'b0;
        end
        else if(count == 2'b11) begin
            count <= 2'b00;
        end
        else
            count <= count + 1'b1;
    end

   always@(posedge clk or posedge rst) begin
      if(rst == 1'b1)
       clk_out <= 1'b0;
      else if(count == 2'b01)
        clk_out <= 1'b1;
      else
        clk_out <= 1'b0;
    end
    


endmodule