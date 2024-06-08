module ad7276_read (
    input  wire       rstn, 
    input  wire       clk,      // require 81.36MHz
    // connect to AD7276
    output reg        ad7276_csn,
    output reg        ad7276_sclk,
    input  wire       ad7276_sdata,
    // 12bit ADC data output
    output reg        adc_data_en,
    output reg [11:0] adc_data
);

initial {ad7276_csn, ad7276_sclk} = 2'b11;
initial {adc_data_en, adc_data} = 0;

reg [ 4:0] cnt = 0;
reg        data_en = 0;
reg [11:0] data = 0;

// cnt runs from 0~31 cyclic
always @ (posedge clk or negedge rstn)
    if(~rstn)
        cnt <= 0;
    else
        cnt <= cnt + 5'd1;


always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        {ad7276_csn, ad7276_sclk} <= 2'b11;
    end else begin
        if(cnt >= 5'd29 || cnt == 5'd0)
            {ad7276_csn, ad7276_sclk} <= 2'b11;
        else
            {ad7276_csn, ad7276_sclk} <= {1'b0, cnt[0]}; // 这里向ADC发送的时钟是40.78MHz，几乎达到AD7276B的上限，采用cnt[0]相当于是时钟的二分频
    end

// 关于这里为什么要传输14个sclk周期，请参见ad7276的datasheet P10。简单来说就是，前两个周期传输的数据是ZERO，所以要先略过

// 由此可以得到为什么主时钟频率需要81.36MHz，这是在载波频率和ADC输入时钟频率之间的一种取舍，将载波频率的6倍频分别进行二分频和六分频后输入比较合适
// 在16个sclk周期中有两个是用于提交数据的（在30、31、0、1中）

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        data_en <= 1'b0;
        data <= 0;
        adc_data_en <= 1'b0;
        adc_data <= 0;
    end else begin
        if(ad7276_csn) begin                     // submit result
            data_en <= 1'b0;
            adc_data_en <= data_en;
            if(data_en) adc_data <= data;
        end else if(ad7276_sclk) begin           // sample at negedge of ad7276_sclk
            data_en <= 1'b1;
            data <= {data[10:0], ad7276_sdata}; // 将SAR ADC的最高位左移传入
            adc_data_en <= 1'b0;
        end
    end
endmodule
