`timescale 1ns/1ns

module tb_pwm;

reg clk;
reg rst_n;
reg [15:0] period;
reg [15:0] duty;
wire pwm_out;

// 50Mhz 时钟 20ns周期
initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
end

initial begin
    $dumpfile("pwm.vcd");
    $dumpvars(0, tb_pwm);
end

pwm u_pwm(
    .clk(clk),
    .rst_n(rst_n),
    .period(period),
    .duty(duty),
    .pwm_out(pwm_out)
);

initial begin
    rst_n = 1'b0;
    period = 16'd50000;
    duty   = 16'd12500; //25%占空比
    #20;
    rst_n = 1'b1;

    // #2000000;
    // duty = 16'd25000; //50%
    // #2000000;
    // duty = 16'd37500; //75%
    // #2000000;
    // duty = 16'd0;     //0%
    // #2000000;
    // duty = 16'd50000; //100%

    #20000000;
    $finish;
end

endmodule
