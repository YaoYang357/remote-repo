/**
    将ad7276_read模块输入的2.5425Mhz的12bit离散电压值转换为同频率的电平值
    用一个数字信号处理(DSP)算法来从 ADC 采样数据中检测 PICC-to-PCD 的 ASK 信号，
    即检测 ADC 采样数据幅度的微小变化，需要有抗噪声能力，并自适应信号幅度
*/

module nfca_rx_dsp (
    input   rstn,
    input   clk,

    // 12bit ADC data input (2.5425Msa/s): 81.36Mhz/32 = 2.5425Msps
    input   adc_data_en,
    input   [11:0]  adc_data,

    // RX DSP result (2.5425 Mbps)
    output reg  rx_ask_en,
    output reg  rx_ask
);

initial {rx_ask_en, rx_ask} = 0;

localparam          N           = 21;
localparam [5:0]    SORT_CYCLES = 6'd24;

reg [5:0] ccnt = 0;                     // count_cnt
reg [5:0] acnt = 0;                     // ask_cnt，用于消除初始化时不稳定情况的计数器
reg [11:0] array [0:(N-1)];             // 未排序的过去21个样点，raw取其中第10个（最中间哪个），即raw是观察窗内最中心的数据
reg [11:0] sorted [0:(N-1)];            // 排序过后的过去21个样点，lpf取其中第12个，可以将lpf看作中值滤波的结果

wire [11:0] lpf = sorted[12];           // lpf means Low-Pass Filter
wire [11:0] raw = array[10];

// ASK解调的DSP算法思路：用中值滤波获取ADC数据的基线（baseline），ADC数据小于baseline一定的值，认为检测到ASK调制的'1'
// 用array存储过去21个ADC样点，每获取一个新样点，就把array赋值给sorted，并用排序网络（冒泡排序）花费22个时钟周期（21排序+1载入）
// 对sorted进行排序，最终得到的sorted的中间数就是中值滤波的结果

integer ii;

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        rx_ask_en <= 1'b0;
        rx_ask    <= 1'b0;
        ccnt <= 0;
        acnt <= 0;
        for (ii=0; ii<N; ii=ii+1) begin
            array[ii] <= 0;
            sorted[ii] <= 0;
        end
    end else begin
        rx_ask_en <= 1'b0;
        if(adc_data_en) begin                               // 输入使能（2.5425MHz），输入原始数据序列
            ccnt <= 0;
            array[0] <= adc_data;
            for(ii=0; ii<N-1; ii=ii+1) array[ii+1] <= array[ii];     // 将输入数据移入未排序序列的最低位
        end else if (ccnt <= 6'd0) begin                    // 将原始数据序列载入排序数据序列等待排序
            ccnt <= ccnt + 6'd1;
            for(ii=0; ii<N; ii=ii+1) sorted[ii] <= array[ii];     

        end else if (ccnt <= SORT_CYCLES) begin             // 花费SORT_CYCLES周期运行冒泡排序网络,实际上考虑到array len=N，只需要N+1个周期就够了，更多无害
            ccnt <= ccnt + 6'd1;

            if(ccnt[0]) begin                                   // 这种交替比较和交换的方式使得每个元素在一次完整的奇数和偶数周期中都有机会被比较和交换。因此，每次完整的奇偶周期（两个时钟周期）可以使数据集中的最大元素向正确的位置移动一步
                for(ii=0; ii<N-1; ii=ii+2) begin                // 排序网络在ccnt为奇数的行为：0/1、2/3、4/5尝试交换
                    if(sorted[ii] > sorted[ii+1]) begin
                        sorted[ii] <= sorted[ii+1];
                        sorted[ii+1] <= sorted[ii];
                    end
                end
            end else begin // (ccnt[0]==1'b0)
                for(ii=1; ii<N; ii=ii+2) begin                  // 排序网络在ccnt为偶数的行为：1/2、3/4、5/6尝试交换
                    if(sorted[ii] > sorted[ii+1]) begin
                        sorted[ii] <= sorted[ii+1];
                        sorted[ii+1] <= sorted[ii];
                    end
                end
            end
        end else if (ccnt == SORT_CYCLES + 6'd1) begin      // 这个条件只在排序完成后进入1次
            ccnt <= ccnt + 6'd1;
            if(acnt[5]) begin                               // acnt记满32之前不要工作
                rx_ask_en <= 1'b1;
                rx_ask <= (lpf - {7'h0, lpf[11:7]} - {8'h0, lpf[11:8]} > raw);              // 若raw < lpf - lpf/128 - lpf/256(raw < 253/256lpf)，认为PICC在发送ASK载波
            end else
                acnt <= acnt + 6'd1;
        end
    end
endmodule