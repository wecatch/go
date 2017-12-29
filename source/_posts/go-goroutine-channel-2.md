title: Go goroutine 和 channel 详解 (二) ：channel
date: 2017-12-01 13:08:19
tags:
- goroutine
categories:
- advanced
---


# 定义

如果说 goroutine 是并发执行的一个 Go program， channel 就是它们之间的连接通道，它提供了 goroutine 之间相互通信的机制。Channel 是有类型的，channel 中使用的 type 称之为 element type，比如 int 类型的 channel 写作为 `chan int`。

Go 使用 make 内建函数创建 channel。
```go
ch := make(chan int)
```
同 map 一样，一个 channel 引用着 make 创建的底层数据结构上，当把 channel 当做函数参数传递时，实际上是拷贝一份 reference，也就是说函数内部和外部引用的是相同的数据结构，所以在函数内部可以直接修改 channel 的值。同其它 reference type 一样，**channel 的 zero value 是 nil**。


**Channel 是可比较的，如果两个 channel 的类型相同，它们可以彼此相互比较**，当然 channel 也可以和 nil 比较。


# 基本操作: send、receive、close

Channel 有两种主要的操作：send 和 receive，综合来讲就是 communication。Go 使用 `<-` 操作符来实现 send 和 receive。Send 操作 `<-` 在 channel 右侧，receive 操作 `<-` 在左侧。

```go
ch <- x //send
x = <- ch //receive
<- ch //receive

```

Channel 还支持第三种操作 `close`，如果 channel 被 close，表明 channel 不会再 send 任何值了，如果还继续对 channel 执行 receive 操作，等 channel 中的值消耗完毕之后，之后返回的是对应 element type 的 zero value，如果对 channel 执行 send 操作，将会引起 panic。
```go

close(ch)

```

# Unbuffered channel

在创建 channel 时可以指定 channel 的容量，如果不指定默认是 0，我们称这种 channel 是 unbuffered channel。

如果在一个 goroutine 中对 unbuffered channel 执行 send 操作将会一直阻塞，直到有另一个不同的 goroutine 对同样的 channel 开始执行 receive 为止，此时通过 channel send 的值会发送到接收端，之后两个 goroutine 才会各自继续执行。

相似地，如果是 receive 操作先执行，也是类似的过程。

**正是因为 unbuffered channel 的这种特性，unbuffered channel 也称之为 synchronous channel**。


# Channel 实践之一：synchronous

```go
package main
import (
    "fmt"
)

func main() {
    c := make(chan int)
    go func(){
        c <- 1
    }
    <-c
    fmt.Println("main goroutine finish ")
}
```
上面的代码展示了利用 unbuffered channel 完成同步的能力，main goroutine 会一直等待直到满足特定条件时才会结束。

# Channel 的实践之二：pipeline

Channel 是用来连接 goroutine 的通道，借此通道可以达到一个 goroutine 负责输入，另一个 goroutine 负责输出，这样的形式称之为 pipeline。

![pipeline](http://ozoxs1p4r.bkt.clouddn.com/WX20171229-170322.png)




