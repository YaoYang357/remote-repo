module uart_tx #(
    // clk frequency
    parameter CLK_FREQ          = 50_000_000,       // unit: Hz

    // UART format
    parameter BAUD_RATE         = 115200,           // Unit: Hz
    parameter PARITY            = "NONE",           // "NONE", "ODD" or "EVEN"
    parameter STOP_BITS         = 2,                // can be 1, 2, 3, 4, ...

    //AXI stream data width
    parameter BYTE_WIDTH        = 1,                // can be 1, 2, 3, 4, ...

    // TX fifo depth
    parameter FIFO_EA           = 0                 // 0:no fifo    1, 2:depth=4    3:depth=3   ...
) (
    input           rstn,
    input           clk,

    // input stream: AXI-stream slave. Associate clock = clk
    output                   i_tready,
    input                    i_tvalid,
    input [8*BYTE_WIDTH-1:0] i_tdata,
    input [  BYTE_WIDTH-1:0] i_tkeep,
    input                    i_tlast,

    // UART TX output signal
    output reg               o_uart_tx
);



//---------------
//  TX fifo     |
//---------------
wire                   f_tready;
reg                    f_tvalid;
reg [8*BYTE_WIDTH-1:0] f_tdata;
reg [  BYTE_WIDTH-1:0] f_tkeep;
reg                    f_tlast;

generate if (FIFO_EA <= 0) begin            // no TX fifo

    assign      i_tready = f_tready;        // 后面给出fifo的ready信号
    always @(*) f_tvalid = i_tvalid;
    always @(*) f_tdata  = i_tdata;
    always @(*) f_tkeep  = i_tkeep;
    always @(*) f_tlast  = i_tlast;

end else begin                              // TX fifo
    localparam          EA          = (FIFO_EA<=2) ? 2 : FIFO_EA;
    localparam          DW          = (1 + BYTE_WIDTH + 8*BYTE_WIDTH);          // 1-bit tlast, (BYTE_WIDTH)-bit tkeep, (8*BYTE_WIDTH)-bit tdata

    reg [DW-1:0] buffer [ ((1<<EA)-1) : 0 ];

    localparam [EA:0] A_ZERO = {{EA{1'b0}}, 1'b0};
    localparam [EA:0] A_ONE  = {{EA{1'b0}}, 1'b1};


    reg  [EA:0] wptr     = A_ZERO;
    reg  [EA:0] wptr_d1  = A_ZERO;
    reg  [EA:0] wptr_d2  = A_ZERO;
    reg  [EA:0] rptr     = A_ZERO;
    wire [EA:0] rptr_next = (f_tvalid & f_tready) ? (rptr + A_ONE) : rptr;

    assign i_tready = (wptr != {~rptr[EA], rptr[EA-1:0]});

    // write pointer
    always @(posedge clk or negedge rstn)
        if(~rstn) begin
            wptr    <= A_ZERO;
            wptr_d1 <= A_ZERO;
            wptr_d2 <= A_ZERO;
        end else begin
            if(i_tvalid & i_tready)
                wptr <= wptr + A_ONE;
            wptr_d1 <= wptr;
            wptr_d2 <= wptr_d1;
        end

    // write
    always @(posedge clk)
        if(i_tvalid & i_tready)
            buffer[wptr[EA-1:0]] <= {i_tlast, i_tkeep, i_tdata};

    // read pointer
    always @(posedge clk or negedge rstn)
        if(~rstn) begin
            rptr <= A_ZERO;
            f_tvalid <= 1'b0;
        end else begin
            rptr <= rptr_next;
            f_tvalid <= (rptr_next != wptr_d2);
        end

    // read
    always @(posedge clk)
        {f_tlast, f_tkeep, f_tdata} <= buffer[rptr_next[EA-1:0]];

    initial {f_tvalid, f_tlast, f_tkeep, f_tdata} = 0;

end endgenerate



//-----------------------------------------------------
// Generate fractional precise upper limit for counter| 生成分数精度上限的计数器，与uart_rx.v中的完全一致，作用相同
//-----------------------------------------------------
localparam      BAUD_CYCLES              = ( (CLK_FREQ*10*2 + BAUD_RATE) / (BAUD_RATE*2) ) / 10 ;
localparam      BAUD_CYCLES_FRAC         = ( (CLK_FREQ*10*2 + BAUD_RATE) / (BAUD_RATE*2) ) % 10 ;
localparam      STOP_BIT_CYCLES          = (BAUD_CYCLES_FRAC == 0) ? BAUD_CYCLES : (BAUD_CYCLES + 1);

localparam [9:0] ADDITION_CYCLES = (BAUD_CYCLES_FRAC == 0) ? 10'b0000000000 :
                                   (BAUD_CYCLES_FRAC == 1) ? 10'b0000010000 :
                                   (BAUD_CYCLES_FRAC == 2) ? 10'b0010000100 :
                                   (BAUD_CYCLES_FRAC == 3) ? 10'b0010010010 :
                                   (BAUD_CYCLES_FRAC == 4) ? 10'b0101001010 :
                                   (BAUD_CYCLES_FRAC == 5) ? 10'b0101010101 :
                                   (BAUD_CYCLES_FRAC == 6) ? 10'b1010110101 :
                                   (BAUD_CYCLES_FRAC == 7) ? 10'b1101101101 :
                                   (BAUD_CYCLES_FRAC == 8) ? 10'b1101111011 :
                                  /*BAUD_CYCLES_FRAC == 9)*/ 10'b1111101111 ;

wire [31:0] cycles [9:0];

assign cycles[0] = BAUD_CYCLES + (ADDITION_CYCLES[0] ? 1 : 0);
assign cycles[1] = BAUD_CYCLES + (ADDITION_CYCLES[1] ? 1 : 0);
assign cycles[2] = BAUD_CYCLES + (ADDITION_CYCLES[2] ? 1 : 0);
assign cycles[3] = BAUD_CYCLES + (ADDITION_CYCLES[3] ? 1 : 0);
assign cycles[4] = BAUD_CYCLES + (ADDITION_CYCLES[4] ? 1 : 0);
assign cycles[5] = BAUD_CYCLES + (ADDITION_CYCLES[5] ? 1 : 0);
assign cycles[6] = BAUD_CYCLES + (ADDITION_CYCLES[6] ? 1 : 0);
assign cycles[7] = BAUD_CYCLES + (ADDITION_CYCLES[7] ? 1 : 0);
assign cycles[8] = BAUD_CYCLES + (ADDITION_CYCLES[8] ? 1 : 0);
assign cycles[9] = BAUD_CYCLES + (ADDITION_CYCLES[9] ? 1 : 0);



//-----------------------------------
//                                  |
//-----------------------------------
localparam [BYTE_WIDTH-1:0] ZERO_KEEP           = 0;

localparam [31:0] PARITY_BITS = (PARITY == "ODD" || PARITY == "EVEN") ? 1 : 0;
localparam [31:0] TOTAL_BITS  = (STOP_BITS >= ('hFFFFFFFF-9-PARITY_BITS)) ? 'hFFFFFFFF : (PARITY_BITS+STOP_BITS+9); // 总位数包括起始位1位，数据为8位，奇偶校验位（如果有），以及停止位（由'STOP_BITS'参数决定）
// 如果 STOP_BITS 加上 PARITY_BITS 再加上9（起始位和数据位）超过了 32 位无符号整数的最大值（即 0xFFFFFFFF），TOTAL_BITS 将被设置为 0xFFFFFFFF。否则，它将是 PARITY_BITS + STOP_BITS + 9。这个计算确保总位数不会溢出，并且在硬件设计中正确配置 UART 的传输位数。


//--------------------------------------
// functional for calculate parity bit |
//--------------------------------------
function  [0:0] get_parity;
    input [7:0] data;
begin
    get_parity = (PARITY == "ODD") ? (~(^(data[7:0]))) :
                 (PARITY == "EVEN") ? (^(data[7:0]))   :
                 /*(PARITY == "NONE")*/     1'b1       ;
end
endfunction



//---------------------------------------
//          Main FSM                    |
//---------------------------------------
localparam [1:0] S_IDLE     = 2'b01 ,       // only in state S_IDLE, state[0] == 1, the goal is to make f_tready pure register-out
                 S_PREPARE  = 2'b00 ,
                 S_TX       = 2'b10 ;

reg [1:0] state = S_IDLE;                   // FSM state register

reg [8*BYTE_WIDTH-1:0] data = 0;
reg [  BYTE_WIDTH-1:0] keep = 0;

reg [9:0]  txbits = 10'b0;
reg [31:0] txcnt = 0;
reg [31:0] cycle = 1;

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        state <= S_IDLE;
        data  <= 0;
        keep  <= 0;
        txbits <= 10'd0;
        txcnt  <= 0;
        cycle  <= 1;
    end else begin
        case(state)
            S_IDLE : begin
                state           <= f_tvalid ? S_PREPARE : S_IDLE;
                data            <= f_tdata;
                keep            <= f_tkeep;
                txbits          <= 10'd0;
                txcnt           <= 0;
                cycle           <= 1;
            end

            S_PREPARE : begin
                data <= (data >> 8);
                keep <= (keep >> 1);
                if (keep[0] == 1'b1) begin
                    txbits <= {get_parity(data[7:0]), data[7:0], 1'b0};
                    state  <= S_TX;
                end else if (keep != ZERO_KEEP) begin
                    state <= S_PREPARE;
                end else
                    state  <= S_IDLE;

                txcnt <= 0;
                cycle  <= 1;
            end

            default : begin     // S_TX
                if (keep[0] == 1'b0) begin
                    data <= (data >> 8);
                    keep <= (keep >> 1);
                end

                if (cycle < ((txcnt<=9) ? cycles[txcnt] : STOP_BIT_CYCLES) ) begin  // cycle loop from 1 to ((txcnt<=9) ? cycles[txcnt] : STOP_BIT_CYCLES)
                    cycle <= cycle + 1'b1;
                end else begin
                    cycle <= 1;
                    txbits <= {1'b1, txbits[9:1]};
                    if ( txcnt < (TOTAL_BITS-1)) begin
                        txcnt <= txcnt + 1;
                    end else begin
                        txcnt <= 0;
                        state <= S_PREPARE;
                    end
                end
            end
        endcase
    end



//-----------------------
// generate UART output |
//-----------------------
initial o_uart_tx = 1'b1;

always @(posedge clk or negedge rstn)
    if(~rstn)
        o_uart_tx <= 1'b1;
    else
        o_uart_tx <= (state == S_TX) ? txbits[0] : 1'b1;



//----------------------------
// generate AXI-Stream TREADY|
//----------------------------
assign f_tready = state[0];     // state == SIDLE

endmodule