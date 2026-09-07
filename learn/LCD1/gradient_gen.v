module gradient_gen(
    input      [8:0]    pixel_x,
    input      [9:0]    pixel_y,
    output reg [15:0]   pixel_color
);

wire [9:0] y_norm;
assign y_norm = pixel_y;

wire [9:0] delta_y;
assign delta_y = y_norm - 10'd107;

wire [5:0] g_val1;
wire [5:0] r_dec;
wire [5:0] g_dec;
wire [4:0] b_inc;

assign g_val1  = y_norm[5:0];
assign r_dec   = delta_y[5:0];
assign g_dec   = delta_y[5:0];
assign b_inc   = delta_y[4:0];

reg [4:0] r_out;
reg [5:0] g_out;
reg [4:0] b_out;

always @(*) begin
    if(y_norm < 10'd107) begin
        r_out = 5'd31;
        g_out = g_val1;
        b_out = 5'd0;
    end
    else if(y_norm < 10'd214) begin
        r_out = (5'd31 > r_dec[4:0]) ? (5'd31 - r_dec[4:0]) : 5'd0;
        g_out = (6'd63 > g_dec)     ? (6'd63 - g_dec)     : 6'd0;
        b_out = b_inc;
    end
    else begin
        r_out = 5'd0;
        g_out = 6'd0;
        b_out = 5'd31;
    end
    pixel_color = {r_out, g_out, b_out};
end

endmodule
