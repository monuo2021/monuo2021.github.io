---
layout: port
title: UART
date: 2021-07-21 13:33:48
tags: 通信协议
categories: 计算机体系结构
descriptions: UART（Universal Asynchronous Receiver/Transmitter），即通用异步接收器/发送器，是最常用的设备间通信协议之一。
---

转载总结自[UART：了解通用异步接收器/发送器的硬件通信协议](https://www.analog.com/cn/analog-dialogue/articles/uart-a-hardware-communication-protocol.html#)

"沟通最大的问题在于，人们想当然地认为已经沟通了。"  ——乔治·萧伯纳

## 一、UART特点

- **串行**

  串行是按位来进行传递，即一位一位的发送和接受。

- **异步**

  异步数据传输过程中，不需要时钟线，直接接发数据，但需要约定通讯协议格式

- **全双工**

  指可以同时进行收发两方向的数据传递。

## 二、接口

![Figure 1. Two UARTs directly communicate with each other.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-01.svg)  

上图是**两个UART彼此直接通信**，其中：

- 发送器（TX）
- 接收器（RX）

TX、RX两个信号主要作用是用于串行通信的串行数据的发送和接收。

![](https://www.analog.com/-/media/images/analog-dialogue/en/volume-54/number-4/articles/uart-a-hardware-communication-protocol/335962-fig-02.svg?w=900)   

如上图**带数据总线的UART**，发送UART连接到以并行形式发送数据的控制数据总线。然后，数据将在传输线路（导线）上一位一位地串行传输到接收UART。反过来，对于接收设备，串行数据会被转换为并行数据。

## 三、数据传输

### 3.1 数据包形式

UART中，传输模式为数据包形式。数据包由**起始位**、**数据帧**、**奇偶校验位**和**停止位**组成。

![Figure 3. UART packet.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-03.svg)  

- **起始位**

  当不传输数据时，UART数据传输线通常保持高电压电平”1“。若要开始数据传输，发送UART会将传输线从高电平拉到**低电平**并保持1个时钟周期。当接收UART检测到高到低电压跃迁时，便开始以波特率对应的频率读取数据帧中的位。

- **数据帧**

  数据帧包含所传输的实际数据。如果使用奇偶校验位，数据帧长度可以是5位到8位。如果不使用奇偶校验位，数据帧长度可以是9位。

- **奇偶校验码**

- **停止位**

  数据结束标志。发送UART将数据传输线保持**高电平**1到2位时间。

### 3.2 UART传输步骤

1. 发送UART从数据总线并行接收数据。

   ![Figure 8. Data bus to the transmitting UART.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-08.svg)  

2. 发送UART将起始位、奇偶校验位和停止位添加到数据帧。

   ![Figure 9. UART data frame at the Tx side.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-09.svg)

3. 从起始位到结束位，整个数据包以串行方式从发送UART送至接收UART。接收UART以预配置的波特率对数据线进行采样。

   ![Figure 10. UART transmission.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-10.svg)  

4. 接收UART丢弃数据帧中的起始位、奇偶校验位和停止位。  ![Figure 11. The UART data frame at the Rx side.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-11.svg)  

5. 接收UART将串行数据转换回并行数据，并将其传输到接收端的数据总线。

   ![Figure 12. Receiving UART to data bus.](https://gitee.com/tanliang-TL/blogpic/raw/master/img/335962-fig-12.svg)  !

## UART工作原理

使用任何硬件通信协议时，首先必须检查数据手册和硬件参考手册。以下是要遵循的步骤：

1. 检查设备的数据手册接口。

2. 在存储器映射下面检查UART地址。

   ![微控制器存储器映射](https://www.analog.com/-/media/images/analog-dialogue/en/volume-54/number-4/articles/uart-a-hardware-communication-protocol/335962-fig-15.jpg?w=900)

3. 检查UART端口的具体信息，例如工作模式、数据位长度、奇偶校验位和停止位。

4. 检查UART操作的详细信息，包括波特率计算。波特率通过以下示例公式进行配置。

5. 对于波特率，务必检查要使用的外设时钟(PCLK)。此示例有26 MHz PCLK和16 MHz PCLK可用。

6. 检查UART配置的详细寄存器。了解计算波特率时的参数.

7. 检查每个寄存器下的详细信息，代入值以计算波特率，然后开始实现UART。
