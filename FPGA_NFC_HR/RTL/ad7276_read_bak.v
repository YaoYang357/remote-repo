/**
    经过低通滤波器后，包络线的频率=副载波频率=847.5kHz，用一个3Msps的ADC来采样副载波，
    根据模块向ADC施加的频率得到频率为2.5425Msps的12bit模拟电压信号的数字化结果，
    这个数字化结果是通过将模拟信号电压值在一定范围内进行量化后得到的离散值。
    将采样结果传送给下级dsp模块进行处理。
*/

module ad7276_read (
    input   rstn,
    input   clk,

    // connect to AD7276BRMZ
    output reg      ad7276_csn,
    output reg      ad7276_sclk,
    input           ad7276_sdata,

    // 12bit ADC data output
    output reg      adc_data_en,
    output reg [11:0] adc_data
);

initial {ad7276_csn, ad7276_sclk} = 2'b11;
initial {adc_data_en, adc_data} = 0;

reg [4:0] cnt = 0;          // frequency division
reg       data_en = 0;
reg [11:0] data = 0;

// cnt runs from 0~31 cyclic
always @(posedge clk or negedge rstn)
    if(~rstn)
        cnt <= 0;
    else
        cnt <= cnt + 5'd1;

always @(posedge clk or negedge rstn)
    if(~rstn)
        {ad7276_csn, ad7276_sclk} <= 2'b11;
    else begin
        if(cnt >= 5'd29 || cnt == 5'd0)
            {ad7276_csn, ad7276_sclk} <= 2'b11;
        else
            {ad7276_csn, ad7276_sclk} <= {1'b0, cnt[0]};    // 这里向ADC发送的时钟是40.78MHz，几乎达到AD7276B的最大时钟频率48MHz，采用cnt[0]相当于是时钟的二分频，从高电平开始
    end    

// 关于这里为什么要传输14个sclk周期，请参见ad7276的datasheet P10。简单来说就是，前两个周期传输的数据是ZERO（前导0），所以要先略过

// 由此可以得到为什么主时钟频率需要81.36MHz，这是在载波频率和ADC输入时钟频率之间的一种取舍，将载波频率的6倍频分别进行二分频和六分频后输入比较合适
// 在16个sclk周期中有两个是用于提交数据的（在30、31、0、1中），相当于对40.68MHz进行16分频

always @(posedge clk or negedge rstn)
    if(~rstn) begin
        data_en <= 1'b0;
        data    <= 0;
        adc_data_en <= 1'b0;
        adc_data    <= 0;
    end else begin
        if(ad7276_csn) begin            // submit result
            data_en <= 1'b0;
            adc_data_en <= data_en;
            if(data_en) adc_data <= data;
        end else if(ad7276_sclk) begin          // sample at negedge of ad7276_sclk
            data_en <= 1'b1;
            data <= {data[10:0], ad7276_sdata};         // SAR ADC，左移寄存器
            adc_data_en <= 1'b0;
        end
    end
endmodule