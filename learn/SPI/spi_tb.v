`timescale 1ns/1ns
module spi_tb;

    reg clk;
    reg rst;
    wire spi_clk;
    reg en_sig;

    wire cs;
    wire out;
    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, spi_tb);
    end


    initial 
    begin
        clk = 0;
        rst = 1;
        en_sig = 0;
        # 100 rst = 0;
        # 100 rst = 1;
        # 100 en_sig = 0;
        # 100 en_sig = 1;

        # 4000 $finish;
    end

    always #5 clk = ~clk;

    spi spi_dut(
        .sys_clk(clk),
        .reset(rst),
        .en_sig(en_sig),
        .spi_clk(spi_clk),
        .cs(cs),
        .out(out)
    );

endmodule



