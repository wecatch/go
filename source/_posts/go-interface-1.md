title: Go interface 详解(一) ：介绍
date: 2017-10-10 22:52:51
tags:
- interface
categories:
- advanced
---

> 本系列是阅读 "The Go Programming Language" 理解和记录。

Go 中的 interface 是一种类型，更准确的说是一种抽象类型 abstract type，一个 interface 就是包含了一系列行为的 method 集合，interface 的定义很简单：

```Go
package io

type Writer interface {
    Write(p []byte) (n int, err error)
}
```

Go 中的 interface 不同于其它语言，它是隐式的 implicitly，这意味着对于一个已有类型，你可以不用更改任何代码就可以让其满足某个 interface。


如果一个 concrete type 实现了某个 interface，我们说这个 concrete type 实现了 interface 包含的所有 method，**必须是所有的 method**。

在 Go 的标准库 `fmt` 中有一系列的方法可以很好的诠释 interface 是如何应用到实践当中的。

```Go
package fmt

func Fprintf(w io.Writer, format string, args ...interface{}) (int, error)

func Printf(format string, args ...interface{}) (int, error) {
    return Fprintf(os.Stdout, format, args...)
}

func Sprintf(format string, args ...interface{}) string {
    var buf bytes.Buffer
    Fprintf(&buf, format, args...)
    return buf.String()
}

```

`Fprintf` 中的前缀 `F` 表示 `File`，意思是格式化的输出被输出到函数指定的第一个 `File` 类型的参数中。

在 `Printf` 函数中，调用 `Fprintf` 时指定的输出是标准输出，这正是 `Printf` 的功能：Printf formats according to a format specifier and writes to standard output，根据指定的格式化要求输出到标准输出，`os.Stdout` 的类型是 `*os.File` 。

同样在 `Sprintf` 函数中，调用 `Fprintf` 时指定的输出是一个指向某个 memory buffer 的指针，其类似一个 `*os.File`。

虽然 `bytes.Buffer` 和 `os.Stdout` 是不同的，但是它们都可以被用于调用同一个函数 `Fprintf`，就是因为 `Fprintf` 的第一个参数是接口类型 `io.Writer` ，而 `bytes.Buffer` 和 `os.Stdout` 都实现了这个 interface，即它们都实现了 `Write` 这个 method，这个 interface 并不是一个 `File` 却完成了类似 `File`的功能。

`Fprintf` 其实并不关心它的第一个参数是一个 file 还是一段 memory，它只是调用了 `Write` method。这正是 interface 所关注的，**只在乎行为，不在乎其值**，这种能力让我们可以非常自由的向 `Fprintf` 传递任何满足 `io.Writer` 的 concrete type，这是 Go interface 带来的 `substitutability` 可替代性，object-oriented programming 的一种重要特性。

看个例子：

```Go
package main

import (
    "fmt"
)

type ByteCounter int


func (c *ByteCounter) Write(p []byte) (int, error) {
    *c += ByteCounter(len(p)) // convert int to ByteCounter
    return len(p), nil
}

func main() {

    var c ByteCounter
    c.Write([]byte("hello"))
    fmt.Println(c) // 5  #1
    fmt.Fprintf(&c, "hello") #2 
    fmt.Println(c) // 10  #3
}
```

`ByteCounter` 实现了 `Write` method，它满足 `io.Writer` interface，`Write` method 计算传给它的 byte slice 的长度并且赋值给自身，所以 `#1` 输出到标准输出的是它的值 5，正如前文所言，调用 `fmt.Fprintf` 时再次调用了 c 的 `Write` method，所以 `#3` 输出是 10。

这就是 Go 中的 interface 所具有的最基本的功能：作为一种 abstract type，实现各种 concrete type 的行为统一。