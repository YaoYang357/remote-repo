`timescale 1ns / 1ps

module tb_nfca_rx_dsp;

    // Inputs
    reg rstn;
    reg clk;
    reg adc_data_en;
    reg [11:0] adc_data;

    // Outputs
    wire rx_ask_en;
    wire rx_ask;
    wire [11:0] rx_lpf_data;
    wire [11:0] rx_raw_data;

    // Instantiate the Unit Under Test (UUT)
    nfca_rx_dsp uut (
        .rstn(rstn),
        .clk(clk),
        .adc_data_en(adc_data_en),
        .adc_data(adc_data),
        .rx_ask_en(rx_ask_en),
        .rx_ask(rx_ask)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #6.15 clk = ~clk; // 81.36 MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize Inputs
        rstn = 0;
        adc_data_en = 0;
        adc_data = 12'h000;

        // Wait for global reset
        #100;
        rstn = 1;

        // Apply test vectors
        repeat (10000) begin // Loop to provide sufficient test inputs
            #393.6;
            adc_data_en = 1;
            adc_data = $random % 4096; // Random 12-bit value
            #12.3;
            adc_data_en = 0;
            #185.7;
        end

        // End simulation after some time
        #10000;
        $finish;
    end

    // Monitor the outputs
    initial begin
        $monitor("Time=%t, adc_data_en=%b, adc_data=%h, rx_ask_en=%b, rx_ask=%b, rx_lpf_data=%h, rx_raw_data=%h",
                 $time, adc_data_en, adc_data, rx_ask_en, rx_ask, rx_lpf_data, rx_raw_data);
    end

    // Additional debug information
    always @ (posedge clk) begin
        if (rx_ask_en)
            $display("Time=%t, rx_ask_en is high", $time);
        if (rx_ask)
            $display("Time=%t, rx_ask is high", $time);
    end

endmodule
