`timescale 1ns/1ns
module test9_tb();
    reg [7:0] m_a;
    reg [7:0] m_b;
    reg [7:0] m_c;
    reg [7:0] m_d;
    wire [7:0] m_min;
test9 tes(
    .a(m_a),
    .b(m_b),
    .c(m_c),
    .d(m_d),
    .min(m_min)
    );
    initial begin
        m_a = 1;
        m_b = 2;
        m_c = 3;
        m_d = 4;
        #20
        $display("8bit %d is minium",m_min);
    end
endmodule