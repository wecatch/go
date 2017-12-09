title: Go interface 详解 (四) ：type assertion
date: 2017-12-01 13:08:19
tags:
- interface
categories:
- advanced
---

> 本系列是阅读 "The Go Programming Language" 理解和记录。

## Type Assertion

Type assertion(断言)是用于 interface value 的一种操作，语法是 x.(T)，x 是 interface type 的表达式，而 T 是 assertd type，被断言的类型。


断言的使用主要有两种情景:
如果 asserted type 是一个 concrete type，一个实例类 type，断言会检查 x 的 dynamic type 是否和 T 相同，如果相同，断言的结果是 x 的 dynamic value，当然 dynamic value 的 type 就是 T 了。换句话说，对 concrete type 的断言实际上是获取 x 的 dynamic value。

如果 asserted type 是一个 interface type，断言的目的是为了检测 x 的 dynamic type 是否满足 T，如果满足，断言的结果是满足 T 的表达式，但是其 dynamic type 和 dynamic value 与 x 是一样的。换句话说，对 interface type 的断言实际上改变了 x 的 type，通常是一个更大 method set 的 interface type，但是保留原来的 dynamic type 和 dynamic value。


我们来看两个例子。

**case 1**

```go
package main

import (
    "fmt"
    "io"
    "os"
)

func main() {

    var w io.Writer
    w = os.Stdout
    w.Write([]byte("hello Go!"))
    fmt.Printf("%T\n", w)
    fw := w.(*os.File)
    fmt.Printf("%T\n", fw)
}

```

在上面的代码中，w 是一个有 `Write` method 的 interface expression，其 dynamic value 是 os.Stdout，断言 `w.(*os.File)` 针对 concrete type `*os.File` 进行的，那么 f 就是 w 的 dynamic value `os.Stdout`。

**case 2**

```go
package main

import (
    "fmt"
    "io"
    "os"
)

func main() {

    var w io.Writer
    w = os.Stdout
    w.Write([]byte("hello Go!"))
    fmt.Printf("%T\n", w)
    rw := w.(io.ReadWriter)
    fmt.Printf("%T\n", rw)
}

```

类似 case 1, 断言 `w.(io.ReadWriter)` 针对 interface type `io.ReadWriter` 进行，那么 rw 是一个 dynamic value 为 `*os.File` 的 interface value。


不论是针对 concrete type 还是 Interface type 如果 assert expression 是 nil assert 都会失败。

```go
var w io.Writer
fw := w.(*os.File) //fail
rw := w.(io.ReadWriter) //fail
```

通常我们仅仅只是想知道 dynamic value 是哪种 concrete type ，可以借助 ok 表达式。
```go
var w io.Writer = os.Stdout
f, ok := w.(*os.File) // success: ok, f == os.Stdout
b, ok := w.(*bytes.Buffer) // failure: !ok, b == nil
```
在 ok 表达式中 nil 不会导致 assertion 失败，如果 assertion 成功 ok 是 true 否则是 false，另一个变量在 assertion 失败时是 asserted type 的 zero value。

OK 表达式经常用在 if 语句中：
```go
if f, ok := w.(*os.File); ok {
// ...use f...
}
```

## Type Switches

Interface 一般被用在这两种场合，一种是像 io.Reader, io.Writer 那样，一个 interface 的 method 真正含义是表达了实现这个 interface 的不同 concrete type 的相似性，意味着这里充分发挥的是 interface method 的表现力。重点在 method，而不是 concrete type。

一种是利用 interface 可以存储不同 concrete type 的能力，在必要的时候根据不同的 concrete type 做不同的处理，这样的用法就是利用 interface 的 assertion 来判断 dynamic type 的类型来做出具体的判断。重点在 concrete type，而不是 method。

Type switch 就是利用 interface 存储不同 concrete type 的能力来实现的 assertion。
```go
switch x.(type) {
    case nil:
case int, uint:
case bool:
case string:
default:
}

```
这种类型的语句叫 type switch，其中 x 是 interface expression，asserted type 是 type 字面量，每个 case 语句可以有一种或多种 types，nil case 匹配的是 x == nil 的情况，default case 匹配的是没有类型匹配的情况。

有时候在 type switch 中我们需要使用 dynamic value，这就需要 type assertion 可以提取 interface 的 dynamic value，同样有这样的语法可以支持这一操作 `switch x := x.(type){}`
```go
package main

import (
    "fmt"
)

func main() {
    var x1 interface{}
    var x2 int
    var x3 string
    var x4 bool

    fmt.Println(sqlQuote(x1))
    fmt.Println(sqlQuote(x2))
    fmt.Println(sqlQuote(x3))
    fmt.Println(sqlQuote(x4))
}

func sqlQuote(x interface{}) string {
    switch x := x.(type) {
    case nil:
        return "null"
    case int, uint:
        return fmt.Sprintf("%d", x)
    case bool:
        if x {
            return "true"
        }

        return "false"
    case string:
        return "string"
    default:
        panic("no match case")
    }
}

```
在上面的例子中被提取的 value 赋值给 x，这在 switch block 中会遮蔽断言表达式 x，但是不会影响 x 在 function 中的使用，因为 switch 和 for 一样也是 block scope。
