1. 奇数分频，如果上升下降沿到(N-1)/2翻转，输出就用或（|），如果到(N-1)/2-1翻转，输出就用与（&）。
1. Verilog门级描述题[4位数值比较器电路_牛客题霸_牛客网 (nowcoder.com)](https://www.nowcoder.com/practice/e02fde10f1914527b6b6871b97aef86d?tpId=301&tqId=5000580&ru=/exam/oj&qru=/ta/verilog-start/question-ranking&sourceUrl=%2Fexam%2Foj%3Fpage%3D1%26tab%3DVerilog%E7%AF%87%26topicId%3D301)

关于门级描述方式，需要注意的是![img](手撕RTL.assets/46077ED178489468665DD9C6C3D39104.png)

上图示例代码中，1表示门类型，2表示门实例名，3表示门实例输出，4及以后位置表示的是门输入，1和2中间还可以添加驱动能力和延迟参数。

3. 行波进位加法器（RCA）和超前进位加法器（LCA）[【HDL系列】超前进位加法器原理与设计 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/101332501)；超前进位加法器是通过公式直接导出最终结果与每个输入的关系，是一种用面积换性能的方法，加法器宽度越大，性能优势越明显。LCA的逻辑门扇入扇出比较大，面积和复杂度都比较高。

```verilog
module rca #(
	parameter width = 4
)(
    input [width-1:0] A,
    input [width-1:0] B,
    input [width-1:0] S,
    
    input C_i,
    output C_o
);
    wire [width:0] C;
    genvar i;
    generate
        for(i = 0; i < width; i = i+1) begin : loop
            full_adder myadder(
                .A   (A[i]),
                .B   (B[i]),
                .C_i (C[i]),
                .S   (S[i]),
                .C_o (C[i+1])
            );
        end
    endgenerate
    assign C[0] = C_i;
    assign C_o = C[Width];
endmodule
```

```verilog
// 4-bit LCA

```

