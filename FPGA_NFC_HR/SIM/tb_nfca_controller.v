
//--------------------------------------------------------------------------------------------------------
// Module  : tb_nfca_controller
// Type    : simulation, top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: testbench for nfca_controller
//           only a simulation for PCD-to-PICC,
//           because there is no PICC model, it can not simulate PICC-to-PCD
//--------------------------------------------------------------------------------------------------------

`timescale 1ps/1ps

module tb_nfca_controller ();

initial $dumpvars(0, tb_nfca_controller);


reg clk = 1'b0;
always #6000 clk = ~clk;   // 81.36MHz approx.


reg        tx_tvalid = 1'b0;
wire       tx_tready;
reg  [7:0] tx_tdata  = 0;
reg  [3:0] tx_tdatab = 0;
reg        tx_tlast  = 0;

wire       carrier_out;


nfca_controller nfca_controller_i (
    .rstn          ( 1'b1              ),
    .clk           ( clk               ),
    .tx_tvalid     ( tx_tvalid         ),
    .tx_tready     ( tx_tready         ),
    .tx_tdata      ( tx_tdata          ),
    .tx_tdatab     ( tx_tdatab         ),
    .tx_tlast      ( tx_tlast          ),
    .rx_on         (                   ),
    .rx_tvalid     (                   ),
    .rx_tdata      (                   ),
    .rx_tdatab     (                   ),
    .rx_tend       (                   ),
    .rx_terr       (                   ),
    .adc_data_en   ( 1'b0              ),
    .adc_data      ( 12'h0             ),
    .carrier_out   ( carrier_out       )
);

// 负责发送一帧数据，数据通过类AXI4-Stream接口传输
task tx_frame;
    input [255:0] data_array;   // 数据序列，256位宽
    input integer byte_len;     // 字节长度，指示发送的数据有多少字节
    input [  3:0] datab;        // 指示最后发送的字节中有几位是有效的，1~8
    integer ii;
begin
    $display("PCD-to-PICC: %d Bytes", byte_len);
    {tx_tvalid, tx_tdata, tx_tdatab, tx_tlast} <= 0;
    @ (posedge clk);
    for (ii=0; ii<byte_len; ii=ii+1) begin
        tx_tvalid <= 1'b1;
        tx_tdata  <= data_array[8*ii+:8];// 8*ii是位选择的起始位置，表示从8*ii位开始；+:8这是选择的位宽度，表示从起始位置开始的8个位，当 ii=0 时，data_array[8*ii+:8] 等价于 data_array[7:0]。
        tx_tdatab <= ii+1 == byte_len ? datab : 4'd8;// 判断当前字节是否为最后一个字节，如是则直接默认该字节每个位都有效
        tx_tlast  <= ii+1 == byte_len;
        @ (posedge clk);// 确保后续的代码在下一个时钟的上升沿时才会执行
        while(~tx_tready) @ (posedge clk);// 如果DUT没有准备好接收，则一直等待
    end
    {tx_tvalid, tx_tdata, tx_tdatab, tx_tlast} <= 0;
end
endtask


initial begin
    tx_frame(256'h00_00_00_26, 1, 4'd8);
    tx_frame(256'h00_00_34_12, 2, 4'd8);// 这里应该是小端发送，34是最后一个字节
    tx_frame(256'h00_12_34_12, 3, 4'd6);
    tx_frame(256'h00_12_56_93, 3, 4'd7);
    tx_frame(256'h34_12_56_93, 4, 4'd1);
    tx_frame(256'h34_12_70_95, 4, 4'd8);
    tx_frame(256'h34_12_6f_95, 4, 4'd8);
    
    @ (posedge clk); // 确保后续的代码在下一个时钟的上升沿时才会执行
    while(~tx_tready) @ (posedge clk);
    repeat(10000) @ (posedge clk); // 等待10000ps/10ns
    $finish;
end


endmodule

