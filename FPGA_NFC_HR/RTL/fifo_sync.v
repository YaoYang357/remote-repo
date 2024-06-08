module fifo_sync #(
    parameter       DW = 8,     // bit width
    parameter       EA = 10     // 9:depth=512  10:depth=1024   11:depth=2048   12:depth=4096
) (
    input           rstn,
    input           clk,

    // input interface
    output          i_rdy,      // input-ready
    input           i_en,       // input-valid
    input [DW-1:0]  i_data,

    // output interface
    input           o_rdy,      // output-ready
    output reg      o_en,       // output-valid
    output reg [DW-1:0] o_data
);

reg [DW-1:0] buffer [((1<<EA)-1) : 0];

localparam [EA:0] A_ZERO = {{EA{1'b0}}, 1'b0};
localparam [EA:0] A_ONE  = {{EA{1'b0}}, 1'b1};

reg [EA:0] wptr          = A_ZERO;
reg [EA:0] wptr_d1       = A_ZERO;
reg [EA:0] wptr_d2       = A_ZERO;
reg [EA:0] rptr          = A_ZERO;
wire [EA:0] rptr_next = (o_en & o_rdy) ? (rptr+A_ONE) : rptr;

assign i_rdy = (wptr != {~rptr[EA], rptr[EA-1:0]}); // i_rdy while syncFIFO is not full.

// write pointer
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        wptr    <= A_ZERO;
        wptr_d1 <= A_ZERO;
        wptr_d2 <= A_ZERO;
    end else begin
        if(i_rdy & i_en)
            wptr <= wptr + A_ONE;
        wptr_d1 <= wptr;
        wptr_d2 <= wptr_d1;
    end

// write
always @(posedge clk)
    if(i_en & i_rdy)
        buffer[wptr[EA-1:0]] <= i_data;

// Read pointer
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        o_en <= 1'b0;
        rptr <= A_ZERO;
    end else begin
        o_en <= (rptr_next != wptr_d2);
        rptr <= rptr_next;
    end

/*
    Used to ensure that read operations are always delayed by two clock cycles compared to write operations, 
    in order to avoid race conditions when both read and write operations occur simultaneously. 
    This ensures that o_en is only valid when the FIFO is not empty.
*/

// Read
always @(posedge clk)
    o_data <= buffer[rptr_next[EA-1:0]];

/*
    The use of rptr_next instead of rptr to read data is to ensure data stability. 
    rptr_next represents the next possible read position, 
    ensuring that data read operations within the current clock cycle 
    always read stable data determined by the previous operation, 
    thereby avoiding competition conditions and data inconsistency.
*/
endmodule