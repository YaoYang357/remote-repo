/*
_________   _________________________________________________________________________________________________________
        |   |  ___________________________________________________________________________________________________  |
        |   |  |                       _________________________________________________________                 |  |
        |   |  |         ___________   |    ____________          _____________                |                 |  |   ____________    ____________
        |   |  | uart_rx | UART RX |   |    |  frame   |          | RFID TX   |                |                 |  |   | FDV301N  |    | Resonant |      ___________
uart_tx |---|->|-------->|  logic  |---|--->|  pack    |--------->| modulate  |--------------->|---------------->|--|-->| N-MOSFET |--->| circuit  |      |         |
        |   |  |         -----------   |    ------------          -------------                |   carrier_out   |  |   |          |    |          |---v->| Antenna |
        |   |  |           uart_rx.v   | nfca_tx_frame.v            | nfca_tx_modulate.v       |                 |  |   ------------    ------------   |  |  Coil   |
        |   |  |    uart_rx_parser.v   |                      rx_on |                          |                 |  |                                  |  |         |
        |   |  |          fifo_sync.v  |                            |                          |                 |  |                                  |  -----------
        |   |  |         ___________   |  ___________         ______V____        ____________  |  _____________  |  |     ___________   ____________   |
        |   |  | uart_tx | UART TX |   |  | bytes   |         | bits    |        | ADC data |  |  | AD7276B   |  |  |     | AD7276B |   | Envelop  |   |
uart_rx |<--|--|<--------|  logic  |<--|--| rebuild |<--------| rebuild |<-------| DSP      |<-|--|ADC reader |<-|<-|-----|   ADC   |<--| detection|<---
        |   |  |         -----------   |  -----------         -----------        ------------  |  -------------  |  | SPI |         |   |          |
        |   |  |          uart_tx.v    |nfca_rx_tobytes.v    nfca_rx_tobits.v   nfca_rx_dsp.v  |  ad7276_read.v  |  |     -----------   ------------
    GND |---|  |                       --------------------------------------------------------|                 |  |
        |   |  |                                      nfca_controller.v                                          |  |
        |   |  ---------------------------------------------------------------------------------------------------  |
        |   |                                    uart2nfca_system_top.v                                             |
---------    --------------------------------------------------------------------------------------------------------
 Host-PC                                               FPGA (fpga_top.v )                                                       Analog Circuit

*/

module fpga_top(
    input       rstn,                   // press button to reset, pressed=0, unpressed=1
    input       clk50m,                 // a 50MHz Crystal Oscillator

    // AD7276 ADC SPI interface
    output wire     ad7276_csn,         // connect to NFC_Breakboard's AD7276_CSN
    output wire     ad7276_sclk,        // connect to NFC_Breakboard's AD7276_SCLK
    input           ad7276_sdata,       // connect to NFC_Breakboard's AD7276_SDATA
    
    // NFC carrier generation signal
    output wire     carrier_out,        // connect to FDV301N(N-MOSFET)'s gate (栅极) NFC_Breakboard's CARRIER_OUT

    // connect to host-PC(USB-to-UART chip, FT232/CP2102/CH340)
    input wire      uart_rx,            // connect to chip's UART-TX
    output wire     uart_tx,            // connect to chip's UART-RX

    // connect to on-board LED's(optional) PS:征途Pro开发板上的led是共阳极的，所以低电平点亮
    output wire     led0,               // led0=0 indicates PLL is normally run
    output wire     led1,               // led1=0 indicates carrier is on
    output wire     led2                // led2=0 indicates PCD-to-PICC communication is done and PCD is waiting for PICC-to-PCD
);

// The NFC controller core needs a 81.36MHz clock
wire clk81m36;
wire clk_locked;

PLL	PLL_inst (
	.areset ( ~rstn      ),     // 高电平复位
	.inclk0 ( clk50m     ),
	.c0     ( clk81m36   ),
	.locked ( clk_locked )
);


// UART-to-NFCA system
wire led2_verse;

uart2nfca_system_top u_uart2nfca_system_top (
    .rstn(clk_locked), // 这里使用了PLL的锁定信号作为复位
    .clk(clk81m36),

    .ad7276_csn(ad7276_csn),
    .ad7276_sclk(ad7276_sclk),
    .ad7276_sdata(ad7276_sdata),

    .carrier_out(carrier_out),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx),

    .rx_on(led2_verse)
);

// LED's assignment
assign led0 = ~clk_locked;
assign led1 = ~carrier_out;
assign led2 = ~led2_verse;
endmodule