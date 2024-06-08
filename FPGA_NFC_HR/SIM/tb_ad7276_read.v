`timescale 1ns/1ns

module tb_ad7276_read;

reg rstn;
reg clk;
reg ad7276_sdata;
wire ad7276_csn;
wire ad7276_sclk;
wire adc_data_en;
wire [11:0] adc_data;

ad7276_read uut (
    .rstn(rstn),
    .clk(clk),
    .ad7276_csn(ad7276_csn),
    .ad7276_sclk(ad7276_sclk),
    .ad7276_sdata(ad7276_sdata),
    .adc_data_en(adc_data_en),
    .adc_data(adc_data)
);

// Clock generation
initial begin
    clk = 0;
    forever #6.13 clk = ~clk; // Generates 81.36 MHz clock
end

// Reset generation
initial begin
    rstn = 0;
    #50 rstn = 1;
end

// Simulate ADC data input
initial begin
    ad7276_sdata = 0;
    #100;

    // Simulate ADC data bits
    #122.6 ad7276_sdata = 1; // D11
    #122.6 ad7276_sdata = 0; // D10
    #122.6 ad7276_sdata = 1; // D9
    #122.6 ad7276_sdata = 0; // D8
    #122.6 ad7276_sdata = 1; // D7
    #122.6 ad7276_sdata = 0; // D6
    #122.6 ad7276_sdata = 1; // D5
    #122.6 ad7276_sdata = 0; // D4
    #122.6 ad7276_sdata = 1; // D3
    #122.6 ad7276_sdata = 0; // D2
    #122.6 ad7276_sdata = 1; // D1
    #122.6 ad7276_sdata = 0; // D0
end

// Monitor
initial begin
    $monitor("Time: %0t, ad7276_csn: %b, ad7276_sclk: %b, adc_data_en: %b, adc_data: %h",
             $time, ad7276_csn, ad7276_sclk, adc_data_en, adc_data);
end

// End simulation
initial begin
    #2000; // Run for enough time to capture ADC data
    $stop;
end

endmodule
