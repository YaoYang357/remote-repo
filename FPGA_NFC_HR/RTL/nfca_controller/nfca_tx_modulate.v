module nfca_tx_modulate (
    input rstn,
    input clk,          // required 81.36Mhz

    // tx bit modulate interface
    output reg tx_req, // to "nfca_tx_frame.v"
    input tx_en,
    input tx_bit,

    // RFID carrier output, connect to a NMOS transistor to drive the antenna coil
    output reg carrier_out,

    // 1:in RX window, 0:out of RX window
    output reg rx_on
);

localparam CARRIER_SETUP = 2048;            // 2kbit
localparam CARRIER_HOLD = 131072;           // 128kbit

initial tx_req = 1'b0;
initial carrier_out = 1'b0;
initial rx_on = 1'b0;

reg [ 1:0] clkcnt = 2'd0;                   // frequency division
reg [ 7:0] ccnt   = 8'd0;                   // 1-bit duration cnt
reg [31:0] wcnt   = 32'hFFFFFFFF;           // bits cnt
reg [ 1:0] bdata  = 2'd0;                   // future bit ---> {current bit, past bit}

// division and bit cnt
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        clkcnt <= 2'd0;
        ccnt   <= 8'd0;
    end else begin
        if(clkcnt >= 2'd2) begin
            clkcnt <= 2'd0;
            ccnt <= ccnt + 8'h01;
        end else begin
            clkcnt <= clkcnt + 2'd1;
        end
    end

// tx_req
always @(posedge clk or negedge rstn)
    if(~rstn)
        tx_req <= 1'b0;
    else
        tx_req <= clkcnt == 2'h0 && ccnt == 8'hff && (wcnt == CARRIER_SETUP || wcnt >= CARRIER_SETUP*2 && wcnt <= CARRIER_SETUP*2 + CARRIER_HOLD || wcnt > CARRIER_SETUP*2 + CARRIER_HOLD + 16);

// wcnt
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        wcnt <= 32'hFFFFFFFF;
        bdata <= 2'd0;
    end else begin
        if(clkcnt >= 2'd2 && ccnt == 8'hff) begin // when a bit duration is fullfilled
            if          (wcnt < CARRIER_SETUP) begin
                wcnt <= wcnt + 1;
            end else if (wcnt == CARRIER_SETUP) begin
                if(tx_en) begin
                    bdata <= {tx_bit, bdata[1]};
                end else begin
                    wcnt <= wcnt + 1;
                end
            end else if (wcnt < CARRIER_SETUP*2) begin
                wcnt <= wcnt + 1;
            end else if (wcnt <= CARRIER_SETUP*2 + CARRIER_HOLD) begin // at the time between [CARRIER_SETUP*2, CARRIER_SETUP*2 + CARRIER_HOLD]
                if(tx_en) begin                                    // once tx_en == 1'b1 
                    wcnt <= CARRIER_SETUP;                         // wcnt is assigned to CARRIER_SETUP
                    bdata <= {tx_bit, 1'b0};                       // bdata is assigned to a reset value which bdata[0] is '0' and bdata[1] is tx_bit
                end else
                    wcnt <= wcnt + 1;
            end else if (wcnt <= CARRIER_SETUP*2 + CARRIER_HOLD + 16) begin // CARRIER_SETUP*2 + CARRIER_HOLD + 16 = 4096 + 131072 + 16 = 135184 bit duration, 135.184kbit / 105.9375kbit/s ~= 1.276s
                wcnt <= wcnt + 1;
            end else if (tx_en) begin
                wcnt <= 0;
                bdata <= {tx_bit, 1'b0};
            end
        end
    end

// carrier_out
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        carrier_out <= 1'b0;
    end else begin
        if      (wcnt == CARRIER_SETUP && ~ccnt[6]) begin       // ccnt[6] == 0 means first 1/4 bit duration in two 1/2 bit duration
            if(ccnt[7])                                         // SECOND half of the bit duration
                carrier_out <= ~ccnt[0] && bdata[1] == 1'b0;    // if current bit == 1'b0, don't need modulation; if current bit == 1'b1, get a sequence X.
            else                                                // FIRST half of the bit duration
                carrier_out <= ~ccnt[0] && bdata[1:0] != 2'b00; // if bdata != 2'd00, means NOT two consecutive zeros, keep no modulation; if bdata != 2'd00, means current and past are all zeros, current modulation must be sequence Z.
        end else if (wcnt <= CARRIER_SETUP*2 + CARRIER_HOLD) begin
            carrier_out <= ~ccnt[0];                            // carrier_out without modulation, bigin with 1
        end else begin                                          // wcnt > CARRIER_SETUP*2 + CARRIER_HOLD
            carrier_out <= 1'b0;                                // close carrier_out
        end                           
    end

//  rx_on
always @(posedge clk or negedge rstn)
    if(~rstn)
        rx_on <= 1'b0;
    else
        rx_on <= wcnt >= CARRIER_SETUP + 7 && wcnt < CARRIER_SETUP*2 - 128;
endmodule