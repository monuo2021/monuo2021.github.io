---
layout: port
title: ELF文件
date: 2021-07-23 18:24:49
tags: 程序员的自我修养
categories: 链接、装载与库
description: ELF文件格式是一种用于二进制文件、可执行文件、目标代码、共享库和核心转储格式文件，是理解链接过程的一个重要知识。
---

ELF文件格式是一个开放标准，各种UNIX系统的可执行文件都采用ELF格式，它有三种不同的类型：

- 可重定位的目标文件（.o）
- 可执行文件（.out）
- 共享库（.so）

在详细讲述 ELF 文件之前，我们先了解**链接**。

## 一、链接

### 1.1 链接的本质

链接的本质就是**合并相同的“节”**。如下图所示，相同的“节”被合并在一起从而形成可执行目标文件：

![sp20210723_115137_721](https://gitee.com/tanliang-TL/blogpic/raw/master/img/sp20210723_115137_721.png)

### 1.2 链接的步骤

- 符号解析
  1. 确定符号引用关系
- 重定位
  2. 合并相关的 .o 文件
  3. 确定每个符号的地址
  4. 在指令中填入新地址

## 二、ELF文件格式

### 2.1 ELF两种视图

- 链接视图（被链接）：可重定位目标文件
- 执行视图（被执行）：可执行目标文件

![sp20210723_123433_495](https://gitee.com/tanliang-TL/blogpic/raw/master/img/sp20210723_123433_495.png)

#### 2.2.1 可重定位目标文件格式

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723124052947.png" alt="image-20210723124052947" style="zoom: 33%;" />

- **ELF 头**

  描述了体系结构和操作系统等基本信息，并指出Section Header Table在文件中的什么位置。包括 16 字节标识信息、文件类型、机器类型、节头表的偏移、节头表的表项大小以及表项个数。

- **.txt** 

  编译后的代码部分

- **.rodata**

  只读数据，如 printf 格式串、switch 跳转表等。

- **.data**

  已初始化的全局变量

- **.bss**

  未初始化全局变量，仅是占位符，不占据任何实际磁盘空间。区别初始化和非初始化是为了空间效率。

- **.symtab**

  存放函数和全局变量（符号表）信息，它不包括局部变量。

- **.rel.txt**

  .txt 节的重定位信息，用于重新修改代码段的指令中的地址信息。

- **.rel.data**

  .data 节的重定位信息，用于对被模块使用或定义的全局变量进行重定位的信息。

- **.debug**

  调试用符号表

- **.strtab**

  包含 symtab 和 debug 节中符号及节名

- **Section header table**

  每个节的节名、偏移和大小。

例如，求一组数的最大值的汇编程序如下：

```assembly
#PURPOSE: This program finds the maximum number of a
#	  set of data items.
#
#VARIABLES: The registers have the following uses:
#
# %edi - Holds the index of the data item being examined
# %ebx - Largest data item found
# %eax - Current data item
#
# The following memory locations are used:
#
# data_items - contains the item data. A 0 is used
# to terminate the data
#
 .section .data
data_items: 		#These are the data items
 .long 3,67,34,222,45,75,54,34,44,33,22,11,66,0

 .section .text
 .globl _start
_start:
 movl $0, %edi  	# move 0 into the index register
 movl data_items(,%edi,4), %eax # load the first byte of data
 movl %eax, %ebx 	# since this is the first item, %eax is
			# the biggest

start_loop: 		# start loop
 cmpl $0, %eax  	# check to see if we've hit the end
 je loop_exit
 incl %edi 		# load next value
 movl data_items(,%edi,4), %eax
 cmpl %ebx, %eax 	# compare values
 jle start_loop 	# jump to loop beginning if the new
 			# one isn't bigger
 movl %eax, %ebx 	# move the value as the largest
 jmp start_loop 	# jump to loop beginning

loop_exit:
 # %ebx is the status code for the _exit system call
 # and it already has the maximum number
 movl $1, %eax  	#1 is the _exit() syscall
 int $0x80
```

使用汇编器将其转换成可重定位目标文件：

```shell
as max.s -o max.o
```

使用 readelf 命令可查看 ELF 信息，-a 标识 all，-h 查看 ELF 头，-S 查看节头表：

```
readelf -a max.o 
```

**ELF头信息**如下：

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723163458548.png" alt="image-20210723163458548" style="zoom:50%;" />

ELF Header中描述了操作系统是 UNIX，体系结构是 X86-64。Section Header Table中有 8 个Section  Header，从文件地址504（0x1f8）开始，每个Section  Header占 64 字节，共 512 字节，到文件地址 0x3f7 结束。这个目标文件没有Program Header。

**Section Headers 节信息**如下：

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723164418299.png" alt="image-20210723164418299" style="zoom:50%;" />

从节头表信息可以得到**目标文件的布局**：

| 起始文件地址 | Section或Header      |
| ------------ | -------------------- |
| 0            | ELF Header           |
| 0x40         | `.text`              |
| 0x6d         | `.data`              |
| 0xa5         | `.bss`（此段为空）   |
| 0x1c0        | `.shstrtab`          |
| 0x1f8        | Section Header Table |
| 0xa8         | `.symtab`            |
| 0x168        | `.strtab`            |
| 0x190        | `.rel.text`          |

`readelf`命令输出的最后一部分：

![image-20210723165921745](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723165921745.png)

**.rel.text**告诉链接器指令中的哪些地方需要做重定位

**.symtab**是符号表。`Ndx`列是每个符号所在的Section编号，例如符号`data_items`在第3个Section里（也就是`.data`段），各Section的编号见Section Header Table。`Value`列是每个符号所代表的地址，在目标文件中，符号地址都是相对于该符号所在Section的相对地址，比如`data_items`位于`.data`段的开头，所以地址是0，`_start`位于`.text`段的开头，所以地址也是0，但是`start_loop`和`loop_exit`相对于`.text`段的地址就不是0了。从`Bind`这一列可以看出`_start`这个符号是`GLOBAL`的，而其它符号是`LOCAL`的，`GLOBAL`符号是在汇编程序中用`.globl`指示声明过的符号。

最后是 **.text段**，使用`objdump`工具可以把程序中的机器指令反汇编（Disassemble）：

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723171103315.png" alt="image-20210723171103315" style="zoom: 50%;" />

可以看出，所有的符号都被替换成地址了，比如`je 26`，26 正是 `.symtab`中 loop_exit 的 Value 值，注意没有加`$`的数表示内存地址，而不表示立即数。

#### 2.2.2 可执行目标文件格式

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723171951012.png" alt="image-20210723171951012" style="zoom: 33%;" />

**与可重定位目标文件不同之处在于：**

- ELF 头中字段 Entry point address 给出了执行程序的第一条指令的地址，而在可重定位目标文件，此字段为 0.
- 多了程序头表，保存了所有Segment的描述信息
- 多了一个 .init 节，用于定义 _init 函数，该函数用于进行可执行目标文件开始执行时的初始化工作。
- 少了两个 .rel 节（无需重定位）

按上一节的步骤分析可执行文件**max**，看看链接器都做了什么改动。

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723172433333.png" alt="image-20210723172433333" style="zoom:50%;" />

在ELF Header中，`Type`改成了`EXEC`，由目标文件变成可执行文件了，`Entry point address`改成了 0x401000（这是`_start`符号的地址），还可以看出，多了 3 个 Program Header，少了 2 个Section Header。

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723174200653.png" alt="image-20210723174200653" style="zoom:50%;" />

在Section Header Table中，`.text`和`.data`段的加载地址分别改成了0x401000和0x402000。`.bss`段没有用到，所以被删掉了。`.rel.text`段就是用于链接过程的，做完链接就没用了，所以也删掉了。

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723174637002.png" alt="image-20210723174637002" style="zoom:50%;" />

多出来的Program Header Table描述了三个Segment的信息。前面的ELF Header、Program Header Table一起组成一个Segment（`FileSiz`指出总长度是0xe8），`.text`段组成一个Segment（总长度是0x2d），`.data`段组成另一个Segment（总长度是0x38）。

`VirtAddr`列指出第一个Segment加载到虚拟地址0x400000（注意在x86平台上后面的`PhysAddr`列是没有意义的，并不代表实际的物理地址），第二个Segment加载到地址0x401000。

`Flg`列指出第一个Segment的访问权限是可读，第二个Segment的访问权限是可读可执行，第三个Segment的访问权限是可读可写。

最后一列`Align`的值0x1000（4K）是x86平台的内存页面大小。在加载时文件也要按内存页面大小分成若干页，文件中的一页对应内存中的一页，对应关系类似于下图所示。

![文件和加载地址的对应关系](https://docs.huihoo.com/c/linux-c-programming/images/asm.load.png)

![image-20210723181214100](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723181214100.png)

原来目标文件符号表中的`Value`都是相对地址，现在都改成绝对地址了。此外还多了三个符号`__bss_start`、`_edata`和`_end`，这些符号在链接脚本中定义，被链接器添加到可执行文件中。

再看一下反汇编的结果

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723181119232.png" alt="image-20210723181119232" style="zoom: 50%;" />

指令中的相对地址都改成绝对地址了，跳转指令后的地址都变成了绝对地址。

![image-20210723182358675](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210723182358675.png)
