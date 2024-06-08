/**
    input: UART input
    output: AXI-Stream (1 vyte data width)
*/

module uart_rx #(
    // clock frequency, unit: Hz
    parameter CLK_FREQ = 50_000_000,

    // UART gormat
    parameter BAUD_RATE = 115200,           // Unit: Hz
    parameter PARITY    = "NONE",           // "NONE", "ODD" or "EVEN"
    
    // RX fifo depth
    parameter FIFO_EA   = 0                 // 0: no fifo   1,2: depth=4    3: depth=8    4: depth=16 ... 10: depth=1024    11: depth=2048 ...
) (
    input   rstn,
    input   clk,

    // UART RX input signal
    input   i_uart_rx,

    // output AXI-Stream master, associated clock = clk
    input           o_tready,       // 't' means "transmisson"
    output reg      o_tvalid,
    output reg [7:0] o_tdata,

    // report whether there's a overflow
    output reg      o_overflow
);

//-----------------------------------------------------
// Generate fractional precise upper limit for counter| 生成分数精度上限的计数器
//-----------------------------------------------------

/*
    波特率（Baud Rate）表示每秒钟传输的符号数，而时钟频率（Clock Frequency）表示每秒钟的时钟周期数。
    为了在数字系统中实现特定的波特率，我们需要知道每个符号（位周期）对应多少个时钟周期。公式如下：
                            BAUD_CYCLES = CLK_FREQ / BAUD_RATE
    "BAUD_CYCLES" 可以翻译为“波特周期数”或“波特率周期”。这个参数用于表示在特定波特率下，每个符号（bit）传输所需的时钟周期数。
    CLK_FREQ : 单位时间内（1s），时钟周期的个数
    1/BAUD_RATE : 传输1个Baud（在这里是1bit）所需要的时间
    二者相乘为传输1Baud所需的时钟周期数，也就是BAUD_CYCLE
*/

/*
    这种方法叫做整数除法的舍入处理（Rounding Division）。它通过在除法操作前进行适当的加法，以减少由于整数除法精度不足而带来的误差。具体来说：
        1.将被除数放大到更高的精度（例如乘以10或20）。
        2.加上一个接近于除数一半的值，以便在除法后能够更接近实际值。
        3.最后再缩小回实际需要的精度。
*/

localparam  BAUD_CYCLES      = ((CLK_FREQ*10*2 + BAUD_RATE) / (BAUD_RATE*2)) / 10;
localparam  BAUD_CYCLES_FRAC = ((CLK_FREQ*10*2 + BAUD_RATE) / (BAUD_RATE*2)) % 10;      // FRAC means fractional

localparam  HALF_BAUD_CYCLES = BAUD_CYCLES / 2;
localparam  THREE_QUARTER_BAUD_CYCLES = (BAUD_CYCLES*3) / 4;

localparam  [9:0] ADDITION_CYCLES = (BAUD_CYCLES_FRAC == 0) ? 10'b0000000000 :
                                    (BAUD_CYCLES_FRAC == 1) ? 10'b0000010000 :
                                    (BAUD_CYCLES_FRAC == 2) ? 10'b0010000100 :
                                    (BAUD_CYCLES_FRAC == 3) ? 10'b0010010010 :
                                    (BAUD_CYCLES_FRAC == 4) ? 10'b0101001010 :
                                    (BAUD_CYCLES_FRAC == 5) ? 10'b0101010101 :
                                    (BAUD_CYCLES_FRAC == 6) ? 10'b1010110101 :
                                    (BAUD_CYCLES_FRAC == 7) ? 10'b1101101101 :
                                    (BAUD_CYCLES_FRAC == 8) ? 10'b1101111011 :
                                  /*(BAUD_CYCLES_FRAC == 9 */ 10'b1111101111 ;

wire [31:0] cycles [9:0];

assign cycles[0] = BAUD_CYCLES + (ADDITION_CYCLES[0] ? 1 : 0); // S
assign cycles[1] = BAUD_CYCLES + (ADDITION_CYCLES[1] ? 1 : 0); // b1
assign cycles[2] = BAUD_CYCLES + (ADDITION_CYCLES[2] ? 1 : 0); // b2
assign cycles[3] = BAUD_CYCLES + (ADDITION_CYCLES[3] ? 1 : 0); // b3
assign cycles[4] = BAUD_CYCLES + (ADDITION_CYCLES[4] ? 1 : 0); // b4
assign cycles[5] = BAUD_CYCLES + (ADDITION_CYCLES[5] ? 1 : 0); // b5
assign cycles[6] = BAUD_CYCLES + (ADDITION_CYCLES[6] ? 1 : 0); // b6
assign cycles[7] = BAUD_CYCLES + (ADDITION_CYCLES[7] ? 1 : 0); // b7
assign cycles[8] = BAUD_CYCLES + (ADDITION_CYCLES[8] ? 1 : 0); // b8
assign cycles[9] = BAUD_CYCLES + (ADDITION_CYCLES[9] ? 1 : 0); // P

//-------------
// Input beat |
//-------------
reg rx_d1 = 1'b0;

always @(posedge clk or negedge rstn)
    if(~rstn)
        rx_d1 <= 1'b0;
    else
        rx_d1 <= i_uart_rx;

//--------------------
// Count continuous 1|
//--------------------
reg [31:0] count1 = 0;

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        count1 <= 0;
    end
    else begin
        if(rx_d1)
            count1 <= (count1 < 'hFFFFFFFF) ? (count1 + 1) : count1;
        else
            count1 <= 0;
    end

//-------------------
//     Main FSM     |
//-------------------
localparam [3:0] TOTAL_BITS_MINUS1 = (PARITY == "ODD" || PARITY == "EVEN") ? 4'd9 : 4'd8; // 总位数（数据位+校验位）的计数

localparam [1:0] S_IDLE     = 2'd0,             // PS: Parameter bit width is usually unnecessary
                 S_RX       = 2'd1,
                 S_STOP_BIT = 2'd2;

reg         [1:0] state    = S_IDLE;
reg         [8:0] rxbits   = 9'd0;                    // 右移寄存器，9位，负责存储数据位8bit和可能的校验位1bit
reg         [3:0] rxcnt    = 4'd0;                    // 位循环计数器，[0~8/9)，表示接收UART发送数据位的位置
reg         [31:0] cycle   = 1;
reg         [32:0] countp  = 33'h1_0000_0000;        // countp >= 0x100000000 means '1' is majority, countp < 0x100000000 means 0' is majority
wire                rxbit  = countp[32];             // countp >= 0x100000000 means corresponds to countp[32] == 1, countp<0x10000000 corresponds to countp[32]==0

wire [7:0] rbyte    = (PARITY == "ODD")  ? rxbits[7:0] :
                      (PARITY == "EVEN") ? rxbits[7:0] :
                    /*(PARITY == "NONE"*/  rxbits[8:1] ; // rxbits = {rbyte, S};

wire parity_correct = (PARITY == "ODD")  ? ((~(^(rbyte))) == rxbits[8]) :
                      (PARITY == "EVEN") ? (  (^(rbyte))  == rxbits[8]) :
                    /*(PARITY == "NONE")*/        1'b1                  ;

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        state <= S_IDLE;
        rxbits <= 9'b0;
        rxcnt <= 4'd0;
        cycle <= 1;                                 // reset counter
        countp <= 33'h1_0000_0000;                  // reset counter
    end else begin
        case (state)
            S_IDLE : begin
                if((count1 >= HALF_BAUD_CYCLES) && (rx_d1 == 1'b0))        // receive a '0' which is followed by continuous '1' for half baud cycles
                    state <= S_RX;
                rxcnt   <= 4'd0;
                cycle   <= 2;                                              // We've already receive a '0', so here cycle = 2
                countp  <= (33'h1_0000_0000 - 33'd1);                      // We've already receive a '0', so here countp = initial_value - 1
            end

            S_RX :
                if(cycle < cycles[rxcnt]) begin
                    cycle <= cycle + 1;
                    countp <= rx_d1 ? (countp + 33'd1) : (countp - 33'd1);
                end else begin
                    cycle <= 1;
                    countp <= 33'h1_0000_0000;

                    if(rxcnt < TOTAL_BITS_MINUS1) begin                 // 移位操作在if判断外，即使rxcnt在此处不满足，当前rxcnt对应的bit位依然移入，不会造成数据丢失
                        rxcnt <= rxcnt + 4'd1;
                        if((rxcnt == 4'd0) && (rxbit == 1'b1))          // cycle[0]: S, should get '0', but get '1', error
                            state <= S_IDLE;                            // RX failed, back to S_IDLE
                    end else begin
                        rxcnt <= 4'd0;
                        state <= S_STOP_BIT;
                    end

                    rxbits <= {rxbit, rxbits[8:1]};                     // put current rxbit to MSB of rxbits, and right shift other bits
                end

            S_STOP_BIT :
                if (cycle < THREE_QUARTER_BAUD_CYCLES) begin            // cycle loop from 1 to THREE_QUARTER_BAUD_CYCLES
                    cycle <= cycle + 1;
                end else begin
                    cycle <= 1;                                         // reset counter
                    state <= S_IDLE;                                    // back to S_IDLE
                end
        endcase
    end

//----------------
// RX result byte|
//----------------
reg       f_tvalid = 1'b0;                // f means fifo
reg [7:0] f_tdata = 8'h0;

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        f_tvalid <= 1'b0;
        f_tdata  <= 8'h0;
    end else begin
        f_tvalid <= 1'b0;
        f_tdata  <= 8'h0;
        if(state == S_STOP_BIT) begin
            if(cycle < THREE_QUARTER_BAUD_CYCLES) begin
                // do nothing
            end else begin 
                if ((count1 >= HALF_BAUD_CYCLES) && parity_correct) begin
                    f_tvalid <= 1'b1;              // fifo input valid
                    f_tdata  <= rbyte;             // received a correct byte, output it, NOT include parity.
                end
            end
        end
    end

//---------
// RX fifo|
//---------
wire f_tready;                              // No introduction

generate if (FIFO_EA <= 0) begin            // no RX fifo

    assign f_tready = o_tready;                  // <--------
    always @(*) o_tvalid = f_tvalid;             // -------->
    always @(*) o_tdata  = f_tdata;              // -------->

end else begin

    localparam      EA      = (FIFO_EA <= 2) ? 2 : FIFO_EA;
    reg [7:0] buffer [((1<<EA)-1) : 0];

    localparam [EA:0] A_ZERO = {{EA{1'b0}}, 1'b0};
    localparam [EA:0] A_ONE  = {{EA{1'b0}}, 1'b1};

    reg [EA:0] wptr         = A_ZERO;
    reg [EA:0] wptr_d1      = A_ZERO;
    reg [EA:0] wptr_d2      = A_ZERO;
    reg [EA:0] rptr         = A_ZERO;
    wire [EA:0] rptr_next   = (o_tvalid & o_tready) ? (rptr+A_ONE) : rptr; // 读使能且读准备

    assign f_tready = (wptr != {~rptr[EA], rptr[EA-1:0]});                 // fifo not full

    //write pointer
    always @(posedge clk or negedge rstn)
        if(~rstn) begin
            wptr <= A_ZERO;
            wptr_d1 <= A_ZERO;
            wptr_d2 <= A_ZERO;
        end else begin
            if(f_tvalid & f_tready)
                wptr <= wptr + A_ONE;
            // 这里wptr打两拍的信号单纯记录wptr过去的状态，即使wptr不更新也要继续更新，所以在if外面
            wptr_d1 <= wptr;
            wptr_d2 <= wptr_d1;
        end

    // fifo write
    always @(posedge clk)
        if(f_tvalid & f_tready)
            buffer[wptr[EA-1:0]] <= f_tdata;

    // read pointer
    always @(posedge clk or negedge rstn)
        if(~rstn) begin
            rptr <= A_ZERO;
            o_tvalid <= 1'b0;
        end else begin
            rptr <= rptr_next;
            o_tvalid <= (rptr_next != wptr_d2);     // 非空则允许读，读指针与两拍之前的写指针比较，保证读取时一定非空
        end

    // fifo read
    always @(posedge clk)
        o_tdata <= buffer[rptr_next[EA-1:0]];       // 用下一个指针读取，保证当前周期内读取的数据是上一周期决定的稳定值

    initial o_tvalid = 1'b0;
    initial o_tdata  = 8'h0;
end endgenerate

//--------------------------
// detect RX fifo overflow |
//--------------------------
initial o_overflow = 1'b0;

always @(posedge clk or negedge rstn)
    if(~rstn)
        o_overflow <= 1'b0;
    else
        o_overflow <= (f_tvalid & (~f_tready));     // fifo 写入数据有效但是fifo不允许写入，说明fifo即将溢出
endmodule