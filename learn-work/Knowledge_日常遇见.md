1. 握手协议？[一道Nvidia的面试题 (qq.com)](https://mp.weixin.qq.com/s/EDAjjVJzzyKstI10fqv6Lw)

    ```verilog
    module valid_ready_to_4phase (
        input clk,
        input reset,
        input valid,
        input ready,
        output reg req,
        output reg ack,
        input data_in,
        output reg data_out
    );
    
    reg [1:0] state;
    localparam IDLE = 2'b00,
               WAIT_ACK = 2'b01,
               DATA_TRANSFER = 2'b10,
               WAIT_REQ_DOWN = 2'b11;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            req <= 0;
            ack <= 0;
            data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        data_out <= data_in; // 数据准备输出
                        req <= 1; // 发出请求信号
                        state <= WAIT_ACK;
                    end
                end
                WAIT_ACK: begin
                    if (ack) begin
                        req <= 0; // 请求信号回落
                        state <= WAIT_REQ_DOWN;
                    end
                end
                WAIT_REQ_DOWN: begin
                    if (!req && ack) begin
                        ack <= 0; // 应答信号回落
                        state <= IDLE; // 回到初始状态
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
    endmodule
    ```

2. 电平标准有哪些？[常用电平标准（TTL、RS232、RS485、RS422）_rs422电平标准-CSDN博客](https://blog.csdn.net/qq_48641886/article/details/127757440)

3. PLL和DLL？[FPGA学习笔记（五）PLL和DLL的区别_pll dll-CSDN博客](https://blog.csdn.net/qq_33194301/article/details/103681263)

4. Lint和CDC？https://zhuanlan.zhihu.com/p/107543484

5. 计数器一次有两个位发生跳变可能会产生毛刺？例如，在一个从 01（二进制）跳变到 10（二进制）的2位计数器中，两位几乎同时发生变化。如果第一位稍微延迟翻转，而第二位先翻转，可能会短暂出现不正确的状态（如从 01 到 11 到 10），这种过渡状态就是毛刺。

6. FPGA实现乒乓操作，和FIFO有什么区别？

7. RISC-V中断相关？
