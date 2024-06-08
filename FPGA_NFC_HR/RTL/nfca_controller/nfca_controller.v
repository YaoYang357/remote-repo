module nfca_controller (
    input rstn,
    input clk,

    // TX byte stream interface for NFC PCD2PICC
    input tx_tvalid,
    output tx_tready,
    input [7:0] tx_tdata,
    input [3:0] tx_tdatab,
    input tx_tlast,

    // RX status
    output rx_on,

    // RX byte stream interface for NFC PICC2PCD
    output rx_tvalid,
    output [7:0] rx_tdata,
    output [3:0] rx_tdatab,
    output rx_tend,
    output rx_terr,

    // 12bit ADC data interface, required sample rate 2.5425Msa/s(81.36Mhz / 32)
    input adc_data_en,
    input [11:0] adc_data,

    // RFID carrier out
    output wire carrier_out
);

// nfca_tx_frame
wire tx_req;
wire tx_en;
wire tx_bit;
wire [2:0] remainb;

// nfca_rx_dsp
wire rx_ask_en;
wire rx_ask;

// nfca_rx_tobits
wire rx_bit_en;
wire rx_bit;
wire rx_end;
wire rx_end_col;
wire rx_end_err;

// mfca


nfca_tx_frame u_nfca_tx_frame(
    .rstn           ( rstn          ),
    .clk            ( clk           ),

    .tx_tvalid      ( tx_tvalid     ),
    .tx_tready      ( tx_tready     ),
    .tx_tdata       ( tx_tdata      ),
    .tx_tdatab      ( tx_tdatab     ),
    .tx_tlast       ( tx_tlast      ),

    .tx_req         ( tx_req        ),      // input
    .tx_en          ( tx_en         ),      // output
    .tx_bit         ( tx_bit        ),      // output

    .remainb        ( remainb       )
);

nfca_tx_modulate u_nfca_tx_modulate (
    .rstn           ( rstn          ),
    .clk            ( clk           ),

    .tx_req         ( tx_req        ),
    .tx_en          ( tx_en         ),
    .tx_bit         ( tx_bit        ),


    .carrier_out    ( carrier_out   ),
    .rx_on          ( rx_on         )
);

nfca_rx_dsp u_nfca_rx_dsp (
    .rstn           ( rstn          ),
    .clk            ( clk           ),

    .adc_data_en    ( adc_data_en   ),
    .adc_data       ( adc_data      ),

    .rx_ask_en      ( rx_ask_en     ),
    .rx_ask         ( rx_ask        )
);

nfca_rx_tobits u_nfca_rx_tobits (
    .rstn           ( rstn          ),
    .clk            ( clk           ),

    .rx_on          ( rx_on         ),

    .rx_ask_en      ( rx_ask_en     ),
    .rx_ask         ( rx_ask        ),

    .rx_bit_en      ( rx_bit_en     ),
    .rx_bit         ( rx_bit        ),

    .rx_end         ( rx_end        ),
    .rx_end_col     ( rx_end_col    ),
    .rx_end_err     ( rx_end_err    )
);

nfca_rx_tobytes u_nfca_rx_tobytes (
    .rstn           ( rstn          ),
    .clk            ( clk           ),

    .rx_on          ( rx_on         ),
    .remainb        ( remainb       ),

    .rx_bit_en      ( rx_bit_en     ),
    .rx_bit         ( rx_bit        ),
    .rx_end         ( rx_end        ),
    .rx_end_col     ( rx_end_col    ),
    .rx_end_err     ( rx_end_err    ),

    .rx_tvalid      ( rx_tvalid     ),
    .rx_tdata       ( rx_tdata      ),
    .rx_tdatab      ( rx_tdatab     ),
    .rx_tend        ( rx_tend       ),
    .rx_terr        ( rx_terr       )
);
endmodule