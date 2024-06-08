/*
    根数输入的副载波高低电平值决定输出的bit为0还是1
    由上级模块得知，rx_ask为1表示接收到数据1，为0则表示接收到数据0
    8个副载波周期是一个位周期，根据数据信号化（2%~10%ASK）和数据编码（曼彻斯特编码）得到输出的bit值并传给下级模块
    输出的bit频率为105.9375kbps
*/

module nfca_rx_tobits(
    input wire rstn,
    input wire clk,

    input wire rx_on, // 0:off, 1:on;on时可以接收数据

    // nfca_rx_dsp模块传输的数据（2.5425 Mbps）2.5425Mbps = 3 * 847.5kbps = 24 * 105.9375kbps
    input wire rx_ask_en,
    input wire rx_ask,

    // RX bit parsed（105.9375 kbps base-band），传向tobytes模块的数据，是位速率
    output reg rx_bit_en, // rx_bit使能，rx_bit输入有效
    output reg rx_bit,    // 不包括S（Start of communication）和E(End of communication)，因为输入的数据只是经过dsp识别后的原始数据，没法区分每位数据的意义
    output reg rx_end,    // 结束会话脉冲，原因为检测到E，或者检测到比特碰撞或其他错误
    output reg rx_end_col,// 指示检测到比特碰撞，在rx_end==1时有效
    output reg rx_end_err // 指示检测到未知错误，例如卡片不符合ISO14443-A标准，或有噪声，或PICC帧过长，在rx_end==1时有效
);

// 仿真用，给输出全赋值为0
initial {rx_bit_en, rx_bit, rx_end, rx_end_err, rx_end_col} = 0;

reg [ 3:0] detect_zeros = 0; // 检测到的低电平值数量
reg [ 3:0] detect_ones  = 0; // 检测到的高电平值数量
// 用于存储过去12个‘rx_ask’信号的移位寄存器，每个移位寄存器对应输出的 1/2bit
reg [11:0] shift0 = 0;
reg [11:0] shift1 = 0;
reg [11:0] shift2 = 0;
reg [11:0] shift3 = 0;
reg [ 4:0] cnt = 0; // 计数器，用于计数采样周期

localparam [1:0] IDLE  = 2'd0,
                 PARSE = 2'd1,
                 STOP  = 2'd2;

reg [1:0] status = IDLE;

reg [3:0] sum [0:3]; // 计数器，sum[i]范围[0,12]

integer i, j;

// bit判断
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        detect_zeros <= 0;
        detect_ones  <= 0;
        {shift3, shift2, shift1, shift0} <= 0;
    end else begin
        if(~rx_on) begin // 非接收时间段
            detect_zeros <= 0;
            detect_ones  <= 0;
            {shift3, shift2, shift1, shift0} <= 0;
        end else if(rx_ask_en) begin // 接收时间段且dsp模块传输使能
            // 1.sum赋初值均为0
            for(i=0; i < 4; i=i+1) sum[i]=0;

            // 2.sum[i]对应shift i，统计shifti中1的个数，范围[0,12]
            for(i=0; i < 12; i=i+1) begin
                sum[0] = sum[0] + {3'd0, shift0[i]};
                sum[1] = sum[1] + {3'd0, shift1[i]};
                sum[2] = sum[2] + {3'd0, shift2[i]};
                sum[3] = sum[3] + {3'd0, shift3[i]};
            end

            for(j=0; j < 4; j=j+1) begin
                detect_ones[j] <= sum[j] >= 4'd3;   // 统计每个1/2it计数器中1的个数，有>=3个1就认为这1/2bit是1
                detect_zeros[j] <= sum[j] <= 4'd1;  // 统计每个1/2bit计数器中0的个数，有<=1个0就认为这1/2bit是0
            end

            {shift3, shift2, shift1, shift0} <= {shift3[10:0], shift2, shift1, shift0, rx_ask}; // 4*12bit左移寄存器
        end
    end

// 发送电路
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        {rx_bit_en, rx_bit, rx_end, rx_end_err, rx_end_col} <= 0;
        cnt <= 0;
        status <= IDLE; 
    end else begin
        {rx_bit_en, rx_bit, rx_end, rx_end_err, rx_end_col} <= 0;

        if(~rx_on) begin                            // 非接收阶段
            cnt <= 0;
            status <= IDLE;                         // 在非接收阶段时重置状态机状态
        end else if (rx_ask_en) begin               // 接收阶段且PICC-to-PCD有效
            if (status == IDLE) begin

                cnt <= 0;
                if(detect_ones == 4'b0010 && detect_zeros == 4'b1101)           // start of communication (S)
                    status <= PARSE;

            end else if (status == PARSE) begin

                if(cnt < 5'd23)                     // 在第24个计数周期才进行数据判断与输出，此时的输出即为位频率105.9375kHz
                    cnt <= cnt + 5'd1;
                else begin
                    cnt <= 0;
                    if     (~(&(detect_ones^detect_zeros))) begin                // noise
                    /*
                        如果detect_ones和detect_zeros的任意位存在冲突（即其逻辑异或结果存在'0'），
                        既没有足够的高电平（至少 3 个高电平）也没有足够的低电平（至多 1 个低电平），则判定为噪声。
                    */

                        {rx_end, rx_end_err} <= 2'b11;
                        status <= STOP;                                          // 表示本次接收窗口内不再接收数据
                    end else if (detect_ones[1:0] == 2'b00) begin                // end of communication (E)
                        rx_end <= 1'b1;
                        status <= STOP;
                    end else if (detect_ones[1:0] == 2'b11) begin                // collision，两个半bit均为1
                        {rx_end, rx_end_col} <= 2'b11;
                        status <= STOP;
                    end else if (detect_ones[1:0] == 2'b10) begin                // logic '1'，从高电平转换到低电平，下降沿触发
                        {rx_bit_en, rx_bit} <= 2'b11;
                    end else if (detect_ones[1:0] == 2'b01) begin                // logic '0'，从低电平转换到高电平，上升沿触发
                        {rx_bit_en, rx_bit} <= 2'b10;
                    end else begin
                        {rx_end, rx_end_err} <= 2'b11;
                        status <= STOP;
                    end
                end
            end
        end
    end

endmodule
