[[C语言\]指针的详解与应用-理论结合实践，真正理解指针！](https://www.bilibili.com/video/BV1Mb4y1X7dz?spm_id_from=333.1245.0.0)

来自B站up主江协科技

---

1. 指针也是一种变量，用于存放其他数据单元的**首地址**。我们称这个指针指向了这个数据单元。
2. 指针所占用的位宽等于系统的位宽。16位系统指针2字节，32位系统4字节，64位系统8字节。保证指针位宽可以存下任意地址。
3. [c语言，定义多个指针的写法，多个指针的声明-CSDN博客](https://blog.csdn.net/qq_35683626/article/details/78225697)。
4. 在使用*p取出指针指向的数据单元时，实际上是将p中的内容作为地址取出该地址的内容，是间接访问。 
5. 指针p++，使指针向下移动1个**数据宽度**，如果是int类型的指针，则最终的地址值+4（假定一个int占4个字节）。
6. 利用下标引用数组等效于指针取内容。

7. 数组与指针的关系：数组就是指针的另一种形态。数组名就是指针变量。

8. 指针应用最常见的形式是：传递参数、传递返回值。比如指针指向了单独的变量，这时如果再让指针++，这时指针指向的内容将不可知。数组越界和指针指向非法的位置其实是一个意思。

9. 在引用之前要确保地址是合法的。

10. 变量可以看作0级指针，指针是1级指针，指针取地址赋值给2级指针。

​	![image-20240111153211815](c_pointer.assets/image-20240111153211815.png)

11. `int fidmax(const int *array, int Count)`，当用**const**修饰指针时，在子函数中array只能读不能写。

12. C语言的返回值有一个弊端就是只能返回一个值，这时可以利用指针的特性，使用指针传递**输出参数**，**可实现多返回函数设计**。详细代码如下：

  ``` c
#include <stdio.h>

int main(int argc, char *argv[])
{
    int Max;
    int Count;
    int a[] = {14, 25, 99, 99, 99, 538, 83, 11};
    
    getMaxAndCount(&Max, &Count, a, 8);
    
    printf("Max = %d, Count = %d", Max, Count);
    
    return 0;
}

//在意义上实现了C语言多返回值，这里max和count是作为返回值存在的
void getMaxAndCount(int *max, int *count, const int *array, int length)
{
    *max = array[0];
    *count = 1;
    
    for(int i = 1; i < length; i++)
    {
        if(array[i] > *max)
        {
            *max = array[i];
            *count = 1;
        }
        else if(array[i] == *max)
        {
            (*count)++;
        }
    }
}
  ```

