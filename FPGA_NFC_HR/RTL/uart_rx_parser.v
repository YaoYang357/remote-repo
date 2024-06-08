/**
    将输入的ASCII字节码变为与字符相对应的hex值，
    比如将输入的‘A’（8’h30, ASCII）转化为4‘h0A
    两个转化后的hex值组合后作为一个字节输出
*/

module uart_rx_parser (
    input       rstn,
    input       clk,

    // uart rx bytes input
    input       uart_rx_byte_en,
    input [7:0] uart_rx_byte,

    // parsed byte stream
    output reg       tvalid,
    output reg [7:0] tdata,
    output reg [3:0] tdatab,
    output reg       tlast
);

initial {tvalid, tdata, tdatab, tlast} = 0;

localparam [7:0] CHAR_0     = 8'h30,    // "0", ASCII
                 CHAR_9     = 8'h39,    // "9"
                 CHAR_A     = 8'h41,    // "A"
                 CHAR_F     = 8'h46,    // "F"
                 CHAR_a     = 8'h61,    // "a"
                 CHAR_f     = 8'h66,    // "f"
                 CHAR_ht    = 8'h09,    // "\t"
                 CHAR_sp    = 8'h20,    // " "
                 CHAR_cr    = 8'h0D,    // "\r"
                 CHAR_lf    = 8'h0A,    // "\n"
                 CHAR_cl    = 8'h3A;    // ":"

/*
    这个函数的思路就是利用差值，首先列出一些关键值的ASCII码，比如0、9、A、a、F、f等
    判断输入的ascii值所属的范围后，用ascii值减去参数值，得到的差值就是转换后的hex值
*/

function  [4:0] ascii2hex;   // Convert ASCII characters to hexadecimal numbers
    input [7:0] ascii;
    reg   [7:0] tmp;
begin
    if          (ascii >= CHAR_0 && ascii <= CHAR_9) begin
        tmp = ascii - CHAR_0;
        ascii2hex = {1'b1, tmp[3:0]};
    end else if (ascii >= CHAR_A && ascii <= CHAR_F) begin
        tmp = ascii - CHAR_A + 8'd10;
        ascii2hex = {1'b1, tmp[3:0]};
    end else if (ascii >= CHAR_a && ascii <= CHAR_f) begin
        tmp = ascii - CHAR_a + 8'd10;
        ascii2hex = {1'b1, tmp[3:0]};
    end else begin
        tmp = ascii;
        ascii2hex = {1'b0, 4'h0};
    end
end
endfunction

wire ishex;
wire isspace = (uart_rx_byte == CHAR_sp) || (uart_rx_byte == CHAR_ht);  // 空格和缩进视为space
wire iscrlf  = (uart_rx_byte == CHAR_cr) || (uart_rx_byte == CHAR_lf);  // 回车换行
wire iscolon = (uart_rx_byte == CHAR_cl);                               // 冒号

wire [3:0] hexvalue;
assign {ishex, hexvalue} = ascii2hex(uart_rx_byte);

localparam [2:0] INIT   = 3'd0,
                 HEXH   = 3'd1,
                 HEXL   = 3'd2,
                 LASTB  = 3'd3,
                INVALID = 3'd4;
reg [2:0] fsm = INIT;

reg [7:0] savedata = 0;

//-------------------------------------------------------------
//              Main FSM : Mealy                              |
//-------------------------------------------------------------
always @(posedge clk or negedge rstn)
    if(~rstn) begin
        {tvalid, tdata, tdatab, tlast} <= 0;
        fsm <= INIT;
        savedata <= 0;
    end else begin
        {tvalid, tdata, tlast} <= 0;
        tdatab <= 4'd8;                 // 默认最后1字节的8位均有效

        if(uart_rx_byte_en) begin       // uart_rx.v输入字节使能
            
            //INIT
            if (fsm == INIT) begin
                if(ishex) begin         // 接收到字母数字，进入HEXH状态，并将转换后的hex值放入存储器的低四位
                    savedata <= {4'h0, hexvalue};
                    fsm      <= HEXH;
                end else if(~iscrlf & ~isspace) begin // 如果是回车换行和空格则保持在INIT状态，其他输入则进入INVALID状态
                    fsm      <= INVALID;
                end
            
            // HEXH/HEXL
            end else if(fsm == HEXH || fsm == HEXL) begin   // HEXH状态时接收下一个字符
                if(ishex) begin         // 接收到字母数字
                    if(fsm == HEXH) begin
                        savedata <= {savedata[3:0], hexvalue}; // 将转换后的4位16进制值左移入寄存器，并进入HEXL状态
                        fsm      <= HEXL;
                    end else begin      // 这里表示已经是HEXL状态且接收到的还是字母数字
                        {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b0}; // 将转换后的完整字节传出
                        savedata <= {4'h0, hexvalue};                     // 将新输入写入低四位，高四位清空
                        fsm <= HEXH;                                      // 状态机转回HEXH
                    end
                end

                else if (iscolon) begin// 如果接收到冒号，进入LASTB状态（最后一个字节）
                    fsm <= LASTB;
                end else if (isspace) begin// 如果接收到空格，保持在HEXL状态
                    fsm <= HEXL;
                end else if (iscrlf) begin  // 如果接收到回车换行，认为当前命令结束，返回INIT状态，当前字节为最后一字节
                    {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b1};
                    fsm <= INIT;
                end else begin              // 如果接收到上述字符之外的其他字符，将当前字节输出并进入INVALID状态，当前字节为最后一字节
                    {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b1};
                    fsm <= INVALID;
                end

            // LASTB
            end else if(fsm == LASTB) begin         // 当前输入字节为最后一字节
                if (ishex) begin // 冒号后的最后一字符是字母数字，一般来讲是数字，用来指定最后1字节的有效位数
                    {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b1};       // 如果是，将当前字节输出，并根据hexvalue设置datab为1~7

                    if (hexvalue == 4'd0)       // 0
                        tdatab <= 4'd1;
                    else if (hexvalue <= 4'd7)  // 1~7
                        tdatab <= hexvalue;
                    fsm <= INVALID;

                end else if(iscrlf) begin   // 如果在冒号之后接收到回车换行符，则输出当前字节并回到INIT状态
                    {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b1};
                    fsm <= INIT;

                end else begin
                    {tvalid, tdata, tlast} <= {1'b1, savedata, 1'b1};
                    fsm <= INVALID;
                end

            // INVALID
            end else if (iscrlf) begin      // INVALID状态，任何情况下接收到回车换行，都回到INIT状态
                fsm <= INIT;
            end

        end

    end
endmodule