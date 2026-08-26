`include "sync_fifo.v"
module sync_fifo_tb;

parameter DW = 8;
parameter DP = 8;

reg                     clk;
reg                     rst_n;
reg                     wr_en;
reg [DW-1:0]            din;
reg                     rd_en;
wire [DW-1:0]           dout;
wire                    empty;
wire                    full;

// 例化FIFO
sync_fifo #(
    .DATA_WIDTH(DW),
    .DEPTH(DP)
) u_sync_fifo (.*);

// 生成系统时钟 100MHz 周期10ns
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// 测试激励
initial begin
    rst_n  = 1'b0;
    wr_en  = 1'b0;
    rd_en  = 1'b0;
    din    = 8'd0;
    #10 rst_n = 1'b1;

    // 阶段1：连续写入8个数据，写满FIFO
    repeat(8) begin
        @(posedge clk);
        wr_en = 1'b1;
        din   = din + 1'b1;
    end
    @(posedge clk);
    wr_en = 1'b0;

    #20;

    // 阶段2：连续读出所有数据
    repeat(8) begin
        @(posedge clk);
        rd_en = 1'b1;
    end
    @(posedge clk);
    rd_en = 1'b0;

    #50;
    $finish;
end

// 导出波形文件
initial begin
    $dumpfile("sync_fifo.vcd");
    $dumpvars(0, sync_fifo_tb);
end

endmodule