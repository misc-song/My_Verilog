module sync_fifo
#(
    parameter DATA_WIDTH = 8,    // 单个数据位宽
    parameter DEPTH      = 8     // FIFO深度，建议2的幂次
)
(
    input  wire                     clk,
    input  wire                     rst_n,      // 异步低电平复位
    // 写端口
    input  wire                     wr_en,      // 写使能，高有效
    input  wire [DATA_WIDTH-1:0]    din,        // 写入数据
    // 读端口
    input  wire                     rd_en,      // 读使能，高有效
    output reg  [DATA_WIDTH-1:0]    dout,       // 读出数据
    // 状态标志
    output reg                      empty,      // 空标志：1=无数据不可读
    output reg                      full        // 满标志：1=空间已满不可写
);

// 计算指针位宽：地址位宽 + 1位冗余位
localparam ADDR_BIT = $clog2(DEPTH);
localparam PTR_WID  = ADDR_BIT + 1;

// 读写指针
reg [PTR_WID-1:0] wr_ptr;
reg [PTR_WID-1:0] rd_ptr;

// FIFO存储数组
reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

// ====================== 1. 写指针逻辑 ======================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= {PTR_WID{1'b0}};
    end
    else if (wr_en && !full) begin
        wr_ptr <= wr_ptr + 1'b1;
    end
end

// ====================== 2. 读指针逻辑 ======================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= {PTR_WID{1'b0}};
    end
    else if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1'b1;
    end
end

// ====================== 3. 写入存储器 ======================
always @(posedge clk) begin
    if (wr_en && !full) begin
        fifo_mem[wr_ptr[ADDR_BIT-1:0]] <= din;  //取wr_ptr的低ADDR_BIT位作为地址 高位作为满标志
    end
end

// ====================== 4. 读出数据 ======================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {DATA_WIDTH{1'b0}};
    end
    else if (rd_en && !empty) begin
        dout <= fifo_mem[rd_ptr[ADDR_BIT-1:0]]; // 取rd_ptr的低ADDR_BIT位作为地址 
    end
end

// ====================== 5. 空、满判断（组合逻辑） ======================
always @(*) begin
    // 空：读写指针完全相等
    empty = (wr_ptr == rd_ptr);
    // 满：最高位相反，低位地址完全相同
    full  = (wr_ptr[PTR_WID-1] != rd_ptr[PTR_WID-1])
         && (wr_ptr[ADDR_BIT-1:0] == rd_ptr[ADDR_BIT-1:0]);
end

endmodule