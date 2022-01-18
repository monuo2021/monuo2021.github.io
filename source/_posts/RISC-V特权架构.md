---
title: RISC-V特权架构
mathjax: true
date: 2022-01-18 09:29:04
tags: RISC-V
categories: 计算机体系结构
description: RISC-V 的官方标准主要分成两部分：用户指令集（User-Level Instruction Set Architecture）与特权架构（Privileged Architecture）。本文主要介绍 RISC-V 特权架构。
---

RISC-V 的官方标准主要分成两部分：**用户指令集**（User-Level Instruction Set Architecture）与**特权架构**（Privileged Architecture）。其目的是希望不同特权架构的处理器可以在 ABI(Application Binary Interface) 互相兼容。也就是说，支持同一用户指令集的处理器可以根据实际需求而在特权架构的设计上采取不同的策略。

这节主要讨论 RISC-V 特权架构，包括以下部分：

- 特权层级，特别是机器模式（Machine Mode, M-Mode）
- 控制状态寄存器
- 机器层级指令集
- 异常和中断

## 特权层级

RISC-V 定义了 3 种工作模式：机器模式(Machine Mode ，M-mode)、超级用户模式(Supervisor Mode，S-Mode)和普通用户模式(User Mode，U-Mode)。每种模式分别对应一个特权层级(Privilege Levels)。其中机器模式的特权层级最高，普通用户模式的特权层级最低。

<img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210828113747657.png" alt="image-20210828113747657" style="zoom: 25%;" />

<img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210828113908821.png" alt="image-20210828113908821" style="zoom:50%;" />

机器级别拥有最高的特权，并且是 RISC-V 硬件平台唯一的强制特权级别。在机器模式(M-mode)中运行的代码通常是受信任的，它具有对机器实现的低级访问权限。M-mode 可以用来管理 RISC-V 上的安全执行环境。U-Mode 和 S-Mode 分别用于常规应用和操作系统使用。下面是支持的特权层级组合：

![image-20210828114810829](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828114810829.png)

从图中可以看出，M-mode 是强迫要求实现的。对于其他的两个模式，一般来说，小规模的嵌入式系统只需要 M-mode 就可以了，而对信息安全有要求的系统，则可能需要 M-mode + U-mode。运行类 UNIX 这样大型操作系统的处理器，则三种模式都需要实现，

## 控制状态寄存器

RISC-V 单独定义了一个控制状态寄存器的地址空间，并分配了 12 位地址来做索引。其中，最高的两位 [11:10] 被用来指示寄存器的读写权限。如果这两位是 2'b11 的话，则表示该寄存器是只读寄存器；否则，该寄存器既可以被读取，又可以被写入。地址位 [9 :8] 表示能访问该寄存器的最低特权层级。例如，对机器模式 CSR，这两位都是 2'b11。

<img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210828152215628.png" alt="image-20210828152215628" style="zoom: 67%;" />

### M-mode CSR 寄存器

<img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210828153648619.png" alt="image-20210828153648619" style="zoom: 50%;" />

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828154345445.png" alt="image-20210828154345445" style="zoom:50%;" />

下面对一些主要的寄存器进行说明：

#### mvendorid 寄存器

32 位的只读寄存器，**用来存储厂商标识代码**。

其取值实际上是衍生于 JEDEC 厂商标识代码。JEDEC 的厂商标识代码分为两部分：第一部分是 Bank 域，设其值为 n；第二部分是只有一字节的 Offset 域，设其值为 m。对于这个 8 位的 Offset 域，其最高位是奇数校验码，其余 7 位对应 Bank 域里面的厂商标识。根据 JEDEC 提供的 n 与 m 数值，RISC-V32 位厂商标识代码可以用如下公式产生：

`Vendor ID=((n-1) << 7) + (m & 0x7F)`

#### marchid（体系架构标识代码）

32 位的只读寄存器，用来**存放 HART 所对应的体系架构的标识代码**。

对于开源的架构来说，这个寄存器的值由 RISC-V 基金会负责在全球分配，其最高位必须是 0。对于商业公司所研发的架构来说，其值由具体的商业公司来分配，但是其最高位必须为 1，其余的位不能 全为零。如果将该寄存器和 mvendorid 寄存器一起使用，则可以唯一地标识 HART 的体系架构。 如果处理器设计者选择不支持这个寄存器，则应该返回零值。

#### mimpid（实现标识代码）

32 位的只读寄存器，**标明处理器的版本号**。该寄存器的格式完全由处理器设计者自行决定，如果处理器设计者选择不支持该寄存器，则应该返回零值。

#### mhartid（硬件线程标识）

给这些 HART 编号索引。在多处理器系统中，HART 的编号无须连续，但是必须至少有一个 HART 必须被编号为零。

#### misa（指令集寄存器）

misa 寄存器的目的是为了**向软件告知处理器具体支持的字长和扩展**，以方便软件的可移植性。

![image-20210828182542768](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828182542768.png)

CSR 寄存器中有些指定字段行为的定义和缩写：

- WIRI：Reserved Writes Ignored，Read Ignore Values(保留写入忽略，读取忽略值)
- WPRI：Reserved Writes Preserve Values, Reads Ignore Values(保留写入保留值，读取忽略值)
- WLRL：Write/Read Only Legal Values(读写合法值)
- WARL：Write Any Values, Reads Legal Values(任意写，读合法值)

**MXL 域**：

- **编码了内部支持的 ISA 宽度**(XLEN).
- 当重置时，总是设置为支持的最宽 ISA。

![image-20210828213409020](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828213409020.png)

**extensions 域**

- 编码了现有的标准扩展。0-25 分别为 A-Z，代表了不同的扩展指令集。如果该架构需要某扩展指令集，则该位设为 1。[8] 为 I，该位总是 1。

- 重置时为最大的扩展集合

  ![image-20210828213952453](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828213952453.png)

#### mstatus（硬件线程状态寄存器）

**标识和控制 HART 的操作状态**。mstatus 寄存器有 32 和 64(128)两个版本

![image-20210828215518514](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828215518514.png)

![image-20210828220311590](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210828220311590.png)

**位描述：**

- XIE：全局中断使能位。X 可以为 M、S、U，代表特权层级。当 HART 运行于 X 模式，对应的中断使能位 XIE 置位 1。低优先级的中断总是关闭，高优先级的中断总是使能。高优先级可以改变特定级别的使能位，用于将控制权交给低权限模式。
- XPIE：用于支持嵌套 trap，保存 XIE 进入中断/异常前的值。
- XPP：用于支持嵌套 trap，保存 trap 发生前的特权级。所以，MPP 位 2 比特，SPP 位 1 比特，UPP 位隐式为 0。当发生中断/异常从 y 特权级进入 x 特权级时，XPIE 设为 xIE，xIE 设为 0，XPP 设为 x。
- XRET：用于从 trap 中返回。当发生中断/异常从 x 特权级返回 y 特权级时，xPIE 设为 1，xIE 设为 xPIE，XPP 设为 y。
- MPRV(Modify PRiVilege)：内存优先级域，修改在所有特权模式下执行 load 和 store 的特权级别。当 MPRV = 0 时，加载和存储行为正常，使用当前特权模式的转换和保护机制。当 MPRV=1 时，加载和存储内存地址被转换和保护，就像当前的特权模式被设置为 MPP 一样。
- MXR (Make eXecutable Readable)：内存优先级域，修改加载访问虚拟内存的权限。当 MXR = 0 时，只有加载标记为可读的页面。当 MXR = 1 时，可以加载标记为可读或可执行的页面。
- SUM (permit Supervisor User Memory access) ：内存优先级域，修改 S-mode 载入和存储访问虚拟内存的权限。当 SUM = 0 时，S-mode 内存访问 U-mode 下可访问的页面将出错。当 SUM=1 时，这些访问是允许的。当基于页面的虚拟内存不生效时，SUM 不起作用。注意，当不在 S-mode 下执行时，SUM 通常被忽略，但当 MPRV=1 和 MPP=S 时，SUM 生效。如果不支持 S-mode 模式，SUM 为 0。
- TVM (Trap Virtual Memory)：虚拟内存管理域，
- TW (Timeout Wait)
- TSR (Trap SRET)
- FS
- XS
- SD：用于反映 FS 或者 XS 的位域是否处于脏（dirty）状态。这个位域是 FS，XS 状态的汇总，方便操作系统上下文切换时快速判断
- SXL、UXL：对于 RV64 系统，分别控制 S-mode 和 U-mode 的 XLEN 值。这些字段的编码与 misa 的 MXL 字段相同。 S-mode 和 U-mode 下的有效 XLEN 分别称为 SXLEN 和 UXLEN。对于 RV32 系统，SXL 和 UXL 字段不存在，并且 SXLEN = 32 和 UXLEN = 32。

#### mscratch（草稿寄存器）

一个 MXLEN 位读/写寄存器，专供机器模式使用。通常，它用于保存指向机器模式 hart-local 上下文空间的指针，并在进入 M-mode 时与用户寄存器交换模式陷阱处理程序。

![image-20210829131238711](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210829131238711.png)

#### 与中断和异常有关的 CSR 寄存器

该部分在异常和中断部分会详细说明。

- mtvec（machine trap vector base-address register，机器模式异常向量基地址寄存器）
- mip（machine interrupt register, pending interrupt，机器模式中断等待寄存器）
- mie（machine interrupt register, interrupt enable，机器模式中断使能寄存器）。
- mcause（machine cause register，机器模式异常原因寄存器）。
- mepc（machine exception program counter，机器模式异常 PC 寄存器）。
- mtval（machine trap value register，机器模式异常值寄存器）。

#### 计数器相关寄存器

- mcycle 与 mcycleh

  RISC-V 中为机器模式定义了一个 64 位的 cycle 寄存器，用来记录机器已经运行的时钟周期数。周期数低 32 位和高 32 位分别存放在 mcycle 和 mcycleh 中

- minstret 与 minstreth

  RISC-V 还为机器模式定义了一个 64 位的 instret 寄存器，用来记录机器已经完 成的指令数（The Number of Instructions Retired）。该寄存器的低 32 位和高 32 位 被分别存放在 minstret 与 minstreth 中

### 定时器

RISC-V 在设计时也对 RTC（Real Time Clock，实时时钟）的实现做了考虑。 实际上，要在真正意义上实现一个实时时钟，需要以下几部分的硬件支持：

- 需要一个时钟定时器（Timer），运行在固定的频率。
- 需要有办法获取当前精确的日期与时间。在桌面系统中，这个时间基准可以通过网络从专门的时间服务器获取。在许多嵌入式系统里，这个时间基准可以通过 GPS 获取。
- 需要有办法能保持时钟定时器的不间断运行。这意味着 RTC 需要有自己的电源域，这样即使处理器的其他部分进入深度休眠状态，RTC 可以依然保持运行。而且 RTC 的电源域一般还需要有替代电源，如电池等。

因此，RISC-V 在其特权架构部分为机器模式定义了两个 64 位的寄存器： mtime 与 mtimecmp。同时，为了方便 RTC 的独立运行，减小实现 RTC 的硬件开销，让多个 HART 能共享 RTC，RISC-V 中将这两个寄存器定义为内存映射寄存器，以映射到内存空间中（而不是像 mcycle 这样定义为 CSR）。而这两个 64 位寄存器在内存空间中的地址，则由具体的实现决定，RISC-V 标准中并没有对它们的地址做硬性规定。

![image-20210829143423163](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210829143423163.png)

#### mtime 寄存器

mtime 是时钟定时器，在所有 RV32 和 RV64 系统上都具有 64 位精度。它一般以比较精确的石英晶体振荡器为时钟源，并以固定的频率（没有明确规定）做计数。许多系统将该频率设置为 32.768 kHz，因为 32.768 kHz 的晶振容易获得，且 32.768 kHz 频率较低，适合做休眠时钟。而且，32 768 是 2 的整数次幂，容易由 32.768 kHz 产生周期为 1s 的时钟。

#### mtimecmp 寄存器

mtimecmp 的主要作用便是将其与 mtime 的值做比较。当 mtime 的值大于或等 于 mtimecmp 时，便可触发产生时钟中断。中断一直保持到通过写入 mtimecmp 寄存器将其清除。

## 异常和中断

### 中断与异常的比较

- 这种由处理器内部事件或程序执行中的事件引起的通常被称作异常
- 这种是由独立于软件运行的外部事件引发的意外事件引起的称为中断。

![image-20210803103711166](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210803103711166.png)

![image-20210803103941671](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210803103941671.png)

![image-20210803104254396](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210803104254396.png)

### RISC-V 中断和异常的触发

对于单个 HART 的机器模式，当异常/中断情况发生时，硬件一般要经历以下的处理步骤：

1. 确定中断是否被屏蔽。
2. 确定异常情况发生的原因。
3. 确定异常情况发生的地址。
4. 确定与异常情况相关的参数。
5. 改变 PC 值，调用中断/异常处理程序，并设置相应的中断比特状态位。

#### 确定中断是否被屏蔽

对于单个 HART 的机器模式，下面两个 CSR 寄存器会影响中断的屏蔽：

- mstatus 寄存器中的 mie 位，这是全局的中断使能位。但是该位不会屏蔽异常处理。
- mie 寄存器中的相关位。

##### mie 寄存器

mie 寄存器是**包含中断使能位**的 XLEN 位读/写寄存器。

![image-20210829223938051](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210829223938051.png)

**位描述：**

- USIE、SSIE、HSIE 是对应特权级的**软中断使能位**
- MTIE、STIE、UTIE 是对应特权级的**时钟中断使能位**
- MEIE、SEIE、UEIE 是对应特权级的**外部中断使能位**

##### mip 寄存器

为对应中断的情况，硬件还需要将 mip 寄存器中的相应位设置为等待(pending)。

![image-20210830011355846](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210830011355846.png)

#### 确定异常情况发生的原因。

当中断或异常发生时，处理器需要正确填写 CSR 寄存器 mcause 中的相关内容。

##### mcause 寄存器

mcause 寄存器是一个 XLEN-bit 可读可写寄存器（这意味着软件也可以修改其内容），用于记录异常/中断发生原因。

![img](https://gitee.com/tanliang-TL/blogpic/raw/master/img/machine_25.png)

**位描述：**

- Interrupt 位(第 31 位)：用来标识这个异常情况是中断还是异常。如果是中断，则该位应该被置 为 1；如果是异常，则该位应被置为 0。

- Exception Code： 用来作为异常编码。 虽然在标准中称其为异常编码，但其也包括中断的情况（在中断情况下，异常编码实际上是中断源编号）。

  <img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210829235334345.png" alt="image-20210829235334345" style="zoom:50%;" />

#### 确定异常情况发生的地址。

对于机器模式，RISC-V 在其特权架构标准中定义了 mepc 寄存器，用来存放异常情况发生时的程序计数器的值。

##### mepc 寄存器

XLEN-bit 可读可写寄存器。用来存放异常情况发生时的 PC 的值。对于异常来说，当前触发异常的指令的 PC 值是一个重要参数，所以 mepc = PC。而对中断来说，mepc 值则会被中断处理程序末尾的 MRET（M-Return）指令用来作为中断返回地址。所以，mepc 需要存放下一条指令的地址。

![img](https://gitee.com/tanliang-TL/blogpic/raw/master/img/machine_24.png)

#### 确定与异常情况相关的参数。

为了帮助异常情况的处理，RISC-V 还在其特权架构标准的机器模式中定义了 mtval 寄存器，以**提供与异常情况相关的参数。**

##### mtval 寄存器

XLEN-bit 可读写寄存器。当内存访问出现异常时，对应的内存读写地址应该被保存在这个寄存器里。

![img](https://gitee.com/tanliang-TL/blogpic/raw/master/img/machine_26.png)

mtval 的内容有以下几种写入方式:

- 写入错误的（虚拟）地址：

  - 当 breakpoint 被触发
  - 指令获取、加载或存储地址未对齐
  - 访问页面错误异常发生时

- 写入第一个故障指令

  - 在非法指令发生时:

- 设置为零
  - 对于其他异常，但未来的标准可能会重新定义其他陷阱的 mtval 设置

#### 改变 PC 值，调用中断/异常处理程序，并设置相应的中断比特状态位。

RISC-V 在其特权架构标准中定义了 mtvec 寄存器，用来**确定异常情况处理程序的地址**。

##### mtvec 寄存器

XLEN-bit 可读可写寄存器。

![img](https://gitee.com/tanliang-TL/blogpic/raw/master/img/machine_09.png)

其中的低两位用来确定中断模式，其余高 30 位被用来作为基地址（BASE）。

<img src="C:\Users\谭梁\AppData\Roaming\Typora\typora-user-images\image-20210830011016192.png" alt="image-20210830011016192" style="zoom:50%;" />

### RISC-V 中断和异常的返回

在机器模式下，当异常情况处理程序完成所有操作后，需要调用 MRET(M-Return，机器返回指令)指令返回。

![image-20210830084407189](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210830084407189.png)

当处理器遇到 MRET 指令时，应将 PC 值置为 mepc 寄存器中的值，这样指令从之前被 异常情况打断的地方继续执行

### 异常和中断(软件要做的事)

<img src="https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210830235250178.png" alt="image-20210830235250178" style="zoom:50%;" />

### 中断等待指令(WFI，Wait for Interrupt)

为了给操作系统多提供一个调度的方法，RISC-V 在其特权架构标准中还定义了中断等待指令，当处理器遇到该指令时，则进入停顿状态，直到中断的发生。

![image-20210830164903429](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210830164903429.png)

当中断发生时，处理器会设置 mepc = PC + 4（即 WFI 之后的那条指令的地址）。 在机器模式下，当中断处理结束，MRET 返回时，则会将 PC 设置为 mepc 的值， 从而使得处理器会执行 WFI 之后的那条指令。

### 环境调用与断点

为了给操作系统和软件调试提供更多调度和中断的方式，RISC-V 标准中还定 义了环境调用指令 ECALL（Environment Call）和断点指令 EBREAK（Environment Breakpoint）。当处理器遇到 ECALL 或 EBREAK 指令时，都会产生异常。其中 ECALL 在机器模式下的异常编码是 11，而 EBREAK 的 异常编码是 3。

RISC-V 的特权架构标准中特别强调，当遇到 ECALL 和 EBREAK 指令时，应该将 mepc 寄存器（此处仅讨论机器模式）的值设置为当前指令的地址，而不是下一条指令的地址。但如果是这样，当异常处理结束时调用 MRET 指令时，似乎又回到了原来的 ECALL/EBREAK 指令，陷入重复执行的死循环。

用 GDB 中的软件断点的操作来具体解释。 当我们需要在 GDB 中设置软件断点时，是在 GDB 命令行中键入“break 断点地址”。当处理器执行到该断点地址时，软件中断被触发后，我们可以检查寄存器的值或读取内存中的内容，然后用 continue（继续执行）命令来继续程序的执行。

![image-20210830231635457](https://gitee.com/tanliang-TL/blogpic/raw/master/img/image-20210830231635457.png)

当处理器运行到对应的断点地址时，会触发 EBREAK 断点异常，进入调试器事先准备好的断点异常处理程序中。在这里，用户可以查看寄存器和内存中的内容。当用户完成寄存器和内存内容查看后，可以在 GDB 命令行中键入“continue” 以继续运行程序。但是在继续运行之前，GDB 会将内存中的 EBREAK 再替换回原先的指令，以避免调试器可能带来的副作用。
