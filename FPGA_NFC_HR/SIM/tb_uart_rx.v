`timescale 1ns/1ps

module tb_uart_rx;

    // Parameters
    localparam CLK_FREQ = 81560000; // 81.56 MHz
    localparam BAUD_RATE = 9600;    // 9600 bps
    localparam PARITY = "NONE";
    localparam FIFO_EA = 0;

    // Signals
    reg clk = 0;
    reg rstn = 0;
    reg i_uart_rx = 1;
    reg o_tready = 1;
    wire o_tvalid;
    wire [7:0] o_tdata;
    wire o_overflow;

    // Instantiate the DUT (Device Under Test)
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .PARITY(PARITY),
        .FIFO_EA(FIFO_EA)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .i_uart_rx(i_uart_rx),
        .o_tready(o_tready),
        .o_tvalid(o_tvalid),
        .o_tdata(o_tdata),
        .o_overflow(o_overflow)
    );

    // Clock generation
    always #6.125 clk = ~clk; // Clock period for 81.56 MHz is 12.25 ns (half period is 6.125 ns)

    // Reset sequence
    initial begin
        rstn = 0;
        #50 rstn = 1;
    end

    // UART RX stimulus
    initial begin
        // Wait for reset
        @(posedge rstn);

        // Send byte 0x26
        send_byte(8'h26);

        // Wait for some time
        #10000;

        // Send byte 0x93
        send_byte(8'h93);

        // Wait for some time
        #10000;

        // Send byte 0x20
        send_byte(8'h20);

        // Finish simulation
        #10000;
        $finish;
    end

    // Task to send a byte via UART RX
    task send_byte(input [7:0] byte);
        integer i;
        begin
            // Start bit
            i_uart_rx = 0;
            #(104167); // One bit period (104.167 us for 9600 baud)

            // Data bits
            for (i = 0; i < 8; i = i + 1) begin
                i_uart_rx = byte[i];
                #(104167);
            end

            // Stop bit
            i_uart_rx = 1;
            #(104167);
        end
    endtask

    // Monitor output
    initial begin
        $monitor("Time: %0dns, o_tvalid: %b, o_tdata: %h, o_overflow: %b", $time, o_tvalid, o_tdata, o_overflow);
    end

endmodule
