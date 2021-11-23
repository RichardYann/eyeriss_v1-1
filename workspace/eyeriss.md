## Eyeriss_convlayer

### 要求

要求针对卷积运算，设计一个卷积运算阵列，能够实现对 LeNet5 模型的第一层卷积运 算。比如，LeNet5 模型的第一层输入图片大小为 28x28，所需要进行的卷积运算为 5x5，卷 积核移动步长为 1。每一次卷积即为 25 个乘法结果相加，移动步长为 1 时，完成整张图片 的卷积总共需要进行 24x24（24=28-5+1）次卷积。如下图 5 表示了整个卷积过程。

**本 project 采用的卷积阵列是 3\*3，输入阵列是 7\*7**

**优化乘法运算**。每一个 PE 单元带一个乘法器，能够实现一个 16 位的有符号数乘 法运算。可以看出该计算过程中，实际上最慢的部分就是乘法运算，因此需要设计 延迟较低的乘法器来使得整个运算速度加快。可考虑使用基于 Booth 编码乘法器。 本次设计中输入数据为有符号 16 位（16 位定点数 15~0，15 位为符号位，14~12 为 整数位，11~0 位小数位），因此乘法器输出结果本应该为 32 位，在这里需要截断， 使得乘法结果依然为 16 位，请参考后面具体的截断方式

**PE 内置存储单元**

每个PE单元要存储 位宽为3，和位宽为7的序列

```verilog
parameter FILTER_SIZE = 3;
parameter DATAIN_W = 7;
parameter DATAIN_L = 7;
parameter DATAO_W = 5;
parameter DATAO_L = 5;

module PE_1_1(
    input clk,rst;
    
    input reg [DATAO_W - 1:0]psum_in;
    input reg [FILTER_SIZE -1:0]filter_in;
    input reg [DAIN_W - 1:0]data_in;
    output [FILTER_SIZE-1:0]filter_out;
    output [DATAIN_W-1:0]data_out;
    output [DATAO_W-1:0]psum_out;
)
    
    
module conv_top(
    input clk,rst;
    input [FILTER_SIZE * FILTERSIZE-1:0]filter;
    input [DATAIN_W *DATAIN_L-1:0]DATA_IN;
    output [DATAO_W * DATAO_L-1:0]DATA_OUT;
)
        
```

