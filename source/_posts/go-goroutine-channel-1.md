title: Go goroutine 和 channel 详解 (一) ：介绍
date: 2017-12-01 13:08:19
tags:
- goroutine
categories:
- advanced
---

> 本系列是阅读 "The Go Programming Language" 理解和记录。

Go 支持两种方式的并发模型: communicating sequential processes(CSP) 和 shared memory multithreading，前者是 goroutine 和 channel 并发模型实现的基础，后者是传统的共享内存的方式，也就是多线程模型。

如何理解 CSP ？简单来说就是通过在不同的 goroutine 之间传递 value 来维护并发的下不同 goroutine 的状态，但是对变量的使用、修改要限制在单一的 goroutine 中。


# 定义

在 Go 中可以并发执行的活动单元称之为 goroutine。当一个 Go 程序启动时，一个执行 main function 的 goroutine 会被创建，称之为 `main goroutine`。创建新的 goroutine 可以使用 go 语句，像这样: go f()，其中 `f` 是一个函数。使用 go 语句开启一个新的 goroutine 之后，go 语句之后的函数调用将在新的 goroutine 中执行，而不会阻塞当前的程序执行。


```go

package main

import (
    "fmt"
    "time"
)

func main() {
    go spinner(100 * time.Millisecond)
    const (
        n = 45
    )
    fibN := fib(n)
    fmt.Printf("\rFibonacci(%d) = %d\n", n, fibN)
}

func spinner(delay time.Duration) {
    for {
        for _, r := range `_\|/` {
            fmt.Printf("\r%c", r)
            time.Sleep(delay)
        }
    }
}

func fib(x int) int {
    if x < 2 {
        return x
    }

    return fib(x-1) + fib(x-2)
}

```

在这个例子中，`go spinner()` 和 fib 两个函数的执行是互不影响的，也就是说它们是两个可以同时执行。


# 例子：并发的时钟 server


为了更好的演示 goroutine 在并发场景下的使用以及它带来的优势，我们一起来完成一个时钟 server，这个 server 非常简单，每次处理一个来自客户端的请求并把当前的时间格式化之后发回客户端， 我们先实现一个不支持 goroutine 的版本，即一次处理一个连接。

```go
package main

import (
    "io"
    "log"
    "net"
    "time"
)

func main() {
    listener, err := net.Listen("tcp", "localhost:8888")
    if err != nil {
        log.Fatal(err)
    }
    for {
        conn, err := listener.Accept()
        if err != nil {
            log.Print(err)
            continue
        }

        handleConn(conn)
    }
}

func handleConn(conn net.Conn) {
    defer conn.Close()
    for {
        _, err := io.WriteString(conn, time.Now().Format("15:04:05\n"))
        if err != nil {
            return
        }
        time.Sleep(1 * time.Second)
    }
}

```
然后我们在实现一个 client 来与 server 连接，client 只负责连接 server 并回显 server 的消息。

```go
package main

import (
    "io"
    "log"
    "net"
    "os"
)

func main() {
    conn, err := net.Dial("tcp", "localhost:8888")
    if err != nil {
        log.Fatal(err)
    }

    defer conn.Close()
    mustCopy(os.Stdout, conn)
}

func mustCopy(dst io.Writer, src io.Reader) {
    if _, err := io.Copy(dst, src); err != nil {
        log.Fatal(err)
    }
}

```
然后我们开始我们的并发实验，首先执行 server 端程序，然后打开一个终端执行一个 client，可以看到 client 会不断输出当前的时间
```bash
go run ch08_03_netcat1.go
13:58:50
13:58:51
13:58:52
13:58:53
13:58:54
13:58:55
13:58:56
13:58:57
13:58:58
```
然后我们再打开一个新的终端执行一个新的 client，发现没有任何输出，但是关闭第一个 client 之后，就会有时间输出。在这个例子中，由于 server 一次只能处理一个来自 client 的连接，所以当有多个 client 并发连接时，后续的 client 必须排队等候。

使用 goroutine 就可以提高 server 的并发处理能力从而解决这个问题，非常简单，只需要在 server 端处理连接的地方加一个go 关键字即可 `go handleConn(conn)`。启用新的 goroutine 之后，同时开启多个 client 都会有时间输出，server 有了并发处理的能力了。


