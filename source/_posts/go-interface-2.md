title: Go interface 详解(二) ：定义和使用
date: 2017-10-12 23:45:03
tags:
- interface
categories:
- advanced
---

> 本系列是阅读 "The Go Programming Language" 理解和记录。

# 定义 interface

正如上文所说，Go interface 是一种类型，一个 interface type 指定了一组 method 集合，如果说一个 concrete type 是一个 interface 的 instance，我们说这个 concrete type 实现了这个 interface 的所有方法。

在 Go 的标准库 `io` package 中定义了很多有用的 interface：
```Go
package io

type Reader interface {
    Read(p []byte)(n intm err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type Closer interface {
    Close() error
}

```

`Reader` 代表任何可以去读 byte 的类型，类似的，`Writer` 代表任何可以写入 byte 的类型，`Closer` 代表任何可以执行 close 的类型。除此之外，我们还能在 io package 中发现其它**组合式的 interface**：
```Go
package io

type ReadWriter interface {
    Reader
    Writer
}

type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}

```
`ReaderWrite` 和 `ReadWriteCloser` 的语法形式和 struct 的 embedding 非常类似，被称为 `embedding interface`，通过这种形式可以便捷的实现一个新的 interface 而不必写出 interface 包含的所有 method。

注意 Go 标准库中对组合 interface 的命名，你应该总是遵循这样的规则。

`ReaderWrite` 也可以用非 embedding 的形式实现：
```Go

type ReadWriter interface {
    Read(p []byte)(n intm err error)
    Write(p []byte) (n int, err error)
}

```

或者是二者的组合：
```Go

type ReadWriter interface {
    Read(p []byte)(n intm err error)
    Writer
}

```

以上的几种实现都是等价的，但是我们更推崇使用 embedding 的形式。

说完了 interface type 的定义，再说说 interface type 使用。

# 实现 interface 并使用

如果一个 concrete type 实现了某个 interface type，其值可以赋值给 interface type 的 instance。
```Go
var w io.Writer
w = os.Stdout
w = new(byte.Buffer)

var rwc io.ReadWriteCloser
rwc = os.Stdout

```

甚至赋值符号右边也可以是 interface instance，只要它们的关系满足**左边 interface type method 集合是右边 interface type method 集合的子集**即可：
```Go
w = rwc
```
`w` method 集合 `{Writer}` 是 `rwc` method 集合 `{Reader, Writer, Closer}` 的子集。

在 Struct 中，在一个类型 T 上直接调用 receiver 是 `*T` 的 method 是合法的，只要 T 是以 variable 的形势存在，看个例子：
```Go
package main

import (
    "fmt"
)

type T struct {
}

func (t *T) String() string {
    return ""
}
```

这样是可以的：
```Go
var t T
t.String()
```

但是这样不行：
```Go
T{}.String()
```

Struct 这个微妙的细节也体现在 interface 的赋值上，只有 `*T` 实现了 `String` 所以 `*T` 才能满足 interface `Stringer`，这样是可以的：
```Go
var _ fmt.Stringer = &t
```

但是这样是不行的：
```Go
// T does not implement fmt.Stringer (String method has pointer)
var _ fmt.Stringer = t 
```
这也是[理解 go interface 的 5 个关键点](http://sanyuesha.com/2017/07/22/how-to-understand-go-interface/)第5点所讲到的。

虽然 interface type 和 concrete type 之间的关系是隐式的 implicitly，但是在某些情况下显式地声明 concrete type 和 interface 的关系则很有用：
```Go
var _ io.Writer = new(bytes.Buffer)
```
`new(bytes.Buffer)` 返回 `bytes.Buffer` 的 pointer，这正是实现 `Writer` 需要的类型。

即使 `nil` 我们也可以显式地进行转换:
```Go
var _ io.Writer = (*bytes.Buffer)(nil)
```

# Empty interface

还有一种很重要的 interface 需要我们注意：**interface{}**，empty interface 没有任何 method。

Method 集合是 interface type 和 concrete type 之间关系的契约，也就是说 interface 向 concrete type 提出了要求说，你必须提供我要求的这些方法才能使用我，但是 empty interface 没有提供任何方法是不是不需要任何方法就可以使用它？的确如此。
```Go
var any interface{}
any = true
any = 12.34
any = "hello"
any = map[string]int{"one": 1}
any = new(bytes.Buffer)
```

Empty interface 可以让任何类型赋值，但是它没有任何方法该如何真正使用它？这就涉及到 type assertion ，从 `interface{}` 获取真正有用的 concrete value，后面我们会讲到。

# 总结

Go interface 提供了在抽象层的组合和使用，只要你愿意你总是能找到一种方法可以在不修改已有包代码的情况下组合使用包中提供的任何功能。
