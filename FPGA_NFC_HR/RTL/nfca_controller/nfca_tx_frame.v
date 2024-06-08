module nfca_tx_frame (
    input wire rstn,
    input wire clk,

    input wire tx_tvalid,
    output reg tx_tready,
    input wire [7:0] tx_tdata,
    input wire [3:0] tx_tdatab, // indicate how many bits are valid in the last byte. range=[1,8]. for the last byte of bit-oriented frame
    input wire tx_tlast,

    input wire tx_req,
    output reg tx_en,
    output reg tx_bit,
    // indicate how many bits remain for an incomplete byte for PICC to send, for nfca_rx_tobytes to reconstruct the bytes
    output reg [2:0] remainb
);

function  [15:0] CRC16;
    input [15:0] crc;
    input [ 7:0] inbyte;
//function automatic logic [15:0] CRC16(input logic [15:0] crc, input logic [7:0] inbyte);
    reg   [ 7:0] tmp;
begin
    tmp = inbyte ^ crc[7:0];
    tmp = tmp ^ {tmp[3:0], 4'h0};
    CRC16 = ({8'h0, crc[15:8]} ^ {tmp, 8'h0} ^ {5'h0, tmp, 3'h0} ^ {12'h0, tmp[7:4]});
end
endfunction

// 这些赋初值都是仿真中用的，不可综合，会被编译器忽略
initial tx_tready = 1'b0;       // 默认后向握手未准备好
initial {tx_en, tx_bit} = 0;    // 数据使能与数据bit置0
initial remainb = 0;            // PICC还需传输的非完整bit数默认置0

reg [ 7:0] buffer [0:4095]; // 字节fifo，存储4096=4KB

// 给reg寄存器进行赋初值在IEEE. 1364-2005 6.2.1 Variable declaration assignment中有详细介绍
reg [ 7:0] rdata = 0; // 从fifo中读出的数据
reg [11:0] wptr = 0;
reg [11:0] rptr = 0;
reg [ 3:0] lastb = 0;
reg [17:0] txshift = 0; // 移位数据寄存器
reg [ 4:0] txcount = 0; // 待输出比特计数器
reg        end_of = 1'b0;
reg        has_crc = 1'b0;
reg [15:0] crc = 16'h6363;
reg        incomplete = 1'b0;

wire short_frame = (rdata == 8'h26 || rdata == 8'h52 || rdata == 8'h35 || rdata[7:4] == 4'h4 || rdata[7:3] == 5'h0F);

always @(posedge clk)
    rdata <= buffer[rptr];

always @(posedge clk)
    if(tx_tready & tx_tvalid)
        buffer[wptr] <= tx_tdata; // 从上一层级的fifo传入的数据段（8bit）

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        // 可综合电路中用复位逻辑对输出信号进行复位，而非使用initial语句
        tx_tready <= 0;
        {tx_bit, tx_en} <= 0;
        remainb <= 0;           // 3bit, 0~7

        {wptr, rptr} <= 0;
        lastb <= 0;             // 4bit
        txshift <= 0;           // 18bit, 2*8+2bit
        txcount <= 0;           // 5bit
        end_of <= 1'b0;
        has_crc <= 1'b0;
        crc <= 16'h6363;
        incomplete <= 1'b0;

    end else begin

        if(tx_tready) begin // 如果允许上级输入
            if(tx_tvalid) begin // 上级输入有效，此处两个if不能合并，合并后逻辑不一致
                crc <= CRC16(crc, tx_tdata);

                if(wptr != 12'hFFF) wptr <= wptr + 12'd1; // 在时钟上升沿写入1byte，同时写指针+1

                lastb <= tx_tdatab==4'd0 ? 4'd1 : tx_tdatab>4'd8 ? 4'd8 : tx_tdatab;

                if(tx_tlast) begin // 输入冒号，表示输入的是最后一字节
                    if(wptr != 12'hFFF) begin // fifo没有溢出
                        txshift <= 0;         // 移位数据寄存器清零
                        txcount <= 5'd1;      // send the S bit (start of communication)
                        tx_tready <= 1'd0;    // 将上级输入允许置0，start to send a frame
                    end else begin             // fifo溢出了
                        wptr <= 0;             // 写指针复位
                        crc  <= 16'h6363;      // crc复位到初始值
                    end
                end
            end

        end else if(txcount != 0) begin // 如果输出bit计数不为0
            if(tx_req) begin // 下级模块请求传输1bit
                {txshift, tx_bit, tx_en} <= {1'b0, txshift, 1'b1}; // 移位操作，将txshift的最低位移向tx_bit向下级模块输出使能
                txcount <= txcount - 5'd1; // 发出了1bit数据，计数器-1
            end

        end else if(rptr == wptr) begin  // 如果读指针==写指针，fifo空了
            if(has_crc) begin // 此时，如果需要crc，就在帧后面添加crc
                txshift <= {~(^crc[15:8]), crc[15:8], ~(^crc[7:0]), crc[7:0]}; // append CRC (16bit + 2bit parity), 因为是低位LSB先发送，所以顺序是这样的
                txcount <= 5'd18; // append CRC (16bit + 2bit parity), CRC的两个字节也需要奇校验
            end else if(end_of) begin // 此时，如果已经输出了最后一个Byte，该结束了
                txshift <= 0;    // 移位输出序列置0
                txcount <= 5'd1; // send the E bit (end of communication)
                end_of  <= 1'b0; // 清除标志
                remainb <= incomplete ? lastb[2:0] : 3'd0; // 如果输入的字节不完整，提示有效的bit有多少位，范围[1, 7]（如果有位就是完整的，所以这里lastb只取[2:0]），例如：93 22 03:2 是一个 bit-oriented 帧。 22 代表：读卡器额外指定 UID 中的 2 个 bit，满足的卡才会响应，不满足的卡就不要响应。后面的 03:2 代表只发送 0x03 (00000011) 的低2位，即 11 。
            end else if(tx_req) begin // 此时，如果恰好又请求了，那么就准备使能+复位，准备接收新字节
                tx_tready <= 1'b1; // 该模块准好接收下一个字节了
                {tx_bit, tx_en} <= 0; // 向下级模块的输出bit与输出使能全部置0
                {wptr, rptr} <= 0; // 读写指针全部置0
            end
            
            // 在fifo空的时候，无论发生什么，crc复位
            has_crc <= 1'b0; // 清空需要crc标志
            crc <= 16'h6363; // 将crc初始值重置为6363

        end else begin
            incomplete <= 1'b0;
            end_of <= 1'b1;
            rptr <= rptr + 12'd1; // 以上情况都不满足，读取下一个字节
            txshift <= {9'd0, ~(^rdata), rdata}; // 9bit空数据+1bit Parity+8bit Data, LSB sned first

            if         (rptr == 12'h0) begin // 第一个字节
                has_crc <= ~(rdata == 8'h93 || rdata == 8'h95 || rdata == 8'h97 || short_frame); // 如果是防碰撞/选择命令（只是SEL还看不出来是不是SELECT Command，而且这只是第一个字节）或者短帧（S+7bits+E）是不需要跟随CRC_A的
                txcount <= short_frame ? 4'd7 : 4'd9; // 如果是短帧，则传送7bit数据位，如果是标准帧，则传送8bit数据位+1bit Parity
            end else if(rptr == 12'h1) begin // 第二个字节
                has_crc <= has_crc | (rdata == 8'h70); // 如果之前就确定有CRC或者要发送一个SELECT Command（NVB==8'h70）
                txcount <= 4'd9; // 标准帧8bit数据+1bit Parity
            end else if(rptr+12'd1 < wptr) begin // inner bytes
                txcount <= 4'd9; // 发送标准帧
            end else if(lastb < 4'd8) begin // 最后一个字节不完整
                incomplete <= 1'b1;
                has_crc <= 1'b0;
                txcount <= {1'h0, lastb}; // 最后一个字节有多少位有效就发多少位，低位先发送
            end else begin
                txcount <= 5'd9; // 最后一个字节完整，发送标准帧
            end
        end
    end

endmodule