/**
    将上级传入的 PICC发送的bit数据位 转化为byte 并发送给下级uart_tx模块
*/

module nfca_rx_tobytes(
    input wire rstn,
    input wire clk,

    input wire rx_on, // 0:0ff, 1:on 在发送模块停止发送的间隙里接收数据

    // indicate how many bits remain for an incomplete byte for PICC to send
    input wire [2:0] remainb,

    // RX bit parsed (105.9375 kbps base-band)
    input wire rx_bit_en,
    input wire rx_bit,
    input wire rx_end,
    input wire rx_end_col,
    input wire rx_end_err,

    // RX byte parsed
    output reg       rx_tvalid,
    output reg [7:0] rx_tdata,
    output reg [3:0] rx_tdatab,
    output reg       rx_tend,
    output reg       rx_terr
);

initial {rx_tvalid, rx_tdata, rx_tend, rx_tdatab, rx_terr} = 0;

reg [3:0] cnt = 0;
reg [7:0] byte_saved = 0;

localparam [2:0] IDLE   = 3'd0,
                 START  = 3'd1,
                 PARSE  = 3'd2,
                 CSTOP  = 3'd3,
                 STOP   = 3'd4;

reg        [2:0] status = IDLE;

wire error_parity = (status==PARSE) & ~(^{rx_bit, byte_saved});  // 因为采用的是奇校验，所以当接收Parity后出现偶数个1则发生校验错误

always @(posedge clk or negedge rstn)
    if(~rstn) begin

        {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= 0; // 输出初始化
        cnt <= 0;
        byte_saved <= 0;
        status <= IDLE;

    end else begin

        {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= 0;

        if(status == CSTOP) begin
            {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1, 8'h00, 4'd0, 1'b1, 1'b0}; // end with collision (step2)
            status <= STOP;

        end else if(~rx_on) begin           // 当rx_on为低时，状态机进入IDLE状态，清空计数器和字节保存寄存器
            cnt <= {1'b0, remainb};

            byte_saved <= 0;

            status <= IDLE;

            if(status == START || status == PARSE)      // 如果在非接收期间的状态是START或者PARSE，表示PICC发送的数据过长了，出现错误
                {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1, byte_saved, cnt, 1'b1, 1'b1};

        end else if(status == IDLE) begin   // 当rx_on为高时，状态机进入START状态
            status <= START;                // 一旦进入START状态，状态机会转移到PARSE状态，准备接收位数据

        end else if(status != STOP) begin

            if(rx_bit_en) begin // 非STOP状态，如果有bit从上级模块传入
                if(cnt < 4'd8) begin
                    cnt <= cnt + 4'd1;
                    byte_saved[cnt] <= rx_bit; // 将PICC没有发送的位空出来，放到发送有效位上，从这里，MSB在前而LSB在后
                end else begin // PICC发送的字节是完整的
                    {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1, byte_saved, 4'd8, error_parity, error_parity};
                    // 一次传输结束，将bit计数器和bit寄存器清空
                    cnt <= 0;
                    byte_saved <= 0;

                    status <= error_parity ? STOP : PARSE;          // 如果奇校验通过，保持或进入PARSE状态，否则进入STOP状态
                end

            end else if(rx_end) begin                   // 当接收到 rx_end 信号时，根据不同情况处理
                status <= rx_end_col ? CSTOP : STOP;    // 出现了bit碰撞，当rx_end_col=1的时候有效

                if(rx_end_col)
                    {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1, byte_saved, cnt, 1'b0, 1'b0}; // end with collision
                else if(rx_end_err | (|cnt)) // 出现未知错误或者已经传送到最后一个bit（之前在cnt>8时cnt已经归零）但是计数器中仍有数据
                    {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1, byte_saved, cnt, 1'b1, 1'b1}; // end with error
                else // 正常结束
                    {rx_tvalid, rx_tdata, rx_tdatab, rx_tend, rx_terr} <= {1'b1,     8'h00, 4'd0, 1'b1, 1'b0}; // end normally, no data need to be transmitted
            end

        end

    end

endmodule