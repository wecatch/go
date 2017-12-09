title: Go interface 详解 (三) ：interface 的值
date: 2017-10-18 12:53:54
tags:
- interface
categories:
- advanced
---

> 本系列是阅读 "The Go Programming Language" 理解和记录。


# Interface value 的赋值

从概念上来讲，interface value 有两部分组成：type 部分是一个 concrete type，vlaue 部分是这个 concrete type 对应的 instance，它们分别称之为 interface value 的 dynamic type 和 dynamic value。

由于 Go 是静态类型的语言，type 是在编译阶段已经定义好的，而 interface 存储的值是动态的，在上面这个概念模型中，type 部分更准确叫法是 type descriptors，主要是提供 concrete type 的相关信息，包括 method、name 等。

下面这几个语句：
```Go
var w io.Writer
w = os.Stdout
w = new(bytes.Buffer)
w = nil
```
变量 `w` 依次存储了三种不同的值，在此我们依次来看看每种不同的值的确切含义。


语句 `var w io.Writer` 声明并初始化了一个 interface value `w`，其值是 `nil`，此时 type 和 value 部分都是 `nil`。

```
w:
    type --> nil
    value --> nil

```
interface value 是否是 nil 取决于其 dynamic type，在 nil 的 interface value 上调用会 panic
```Go
w.Write([]byte("hello")) // panic
```

语句 `w = os.Stdout` 赋值 `*os.File` 类型的 value 给 w，这个赋值操作包含一个隐式的类型转换，用以把 concrete type 转换成 interface type `io.Writer(*os.File)`，在这个转换过程中 dynamic type 被赋值为 `*os.File` 类型，在这里其实是它的 type descriptor，同样得，dynamic value 赋值为 os.Stdout 的一份 copy，一个指向 `os.File` 类型的指针且代表**标准输出**的变量。
```
w:
    type --> *os.File
    value -------> fd int=1(stdout)

```

在 interface value w 上调用 `Write` method 实际上调用的是 `*os.File` 类型的 Write 方法，于是输出 "hello"。
```Go
w.Write([]byte("hello")) // "hello"
```

由于在编译阶段，我们并不知道一个 interface value 的 dynamic type 是什么，所以 interface value 的调用必须进行 dynamic dispatch。为了能调用 dynamic value 的 Write method，compiler 必须生成相关代码以便在执行的时候通过 dynamic type 获取对应 method 的真实地址的 copy，在调用的形式上好像是我们直接调用了 dynamic value 的 Write method。
```Go
os.Stdout.Write([]byte("hello")) // "hello"
```

语句 `w=new(bytes.Buffer)` 赋值 `*bytes.Buffer` 类型的 value 作为 w 的 dynamic value，对 w 的处理是也类似的，调用 Write method 将调用 `*bytes.Buffer` 的 Write method。

语句 `w=nil` 和初始语句一样将 w 重置为 nil。


# Interface value 的比较

Interface value 可以使用 `==` 和 `!=` 语句进行比较的。如果两个 interface value 的 dynamic type 相同，dynamic value 根据 dynamic type 的 `==` 比较操作是相等的，那么这两个 interface value 是相等的。因而 interface value 可以用在 map 中作为key 或者 switch 语句中。

虽然 interface value 本身是可以比较的，但是如果 dynamic type 不支持 compare 操作，那么对两个 dynamic type 相同的 interface value 比较将 panic，比如 slice。
```Go
var x interface{} = []int{1, 2, 3}
fmt.Println(x == x) // panic: comparing uncomparable type []int
```
所以使用时你应该总是留意，interface value 的 dynamic 是不是可以 compare 类型，不管 interface value 单独出现还是出现在其它类型中。


# 格式化输出 interface value

Go 提供了格式化输出 interface value 的方法，方便在开发和调试中使用。
```Go
var w io.Writer
fmt.Printf("%T\n", w) // "<nil>"

w=os.Stdout
fmt.Printf("%T\n", w) // "*os.File"

w=new(bytes.Buffer)
fmt.Printf("%T\n", w) // "*bytes.Buffer"
```

# 警告：dynamic value 是 nil 的 interface value 并不是 nil

Interface value 是 nil 和 interface value 包含的 dynamic value 是 nil 并不是一回事，**后者不是 nil**，这个潜在的区别给初学 Go 的 developer 造成了一定的困扰。
```Go
const debug = false

func main() {
    var buf *bytes.Buffer
    if debug {
        buf = new(bytes.Buffer) // enable collection of output
    }
    f(buf) // NOTE: subtly incorrect!
    if debug {
        // ...use buf...
    }
}

// If out is non-nil, output will be written to it.
func f(out io.Writer) {
    // ...do something...
    if out != nil {
        out.Write([]byte("done!\n"))
    }
}
```

在上面的代码中，函数 f 中将会出现 panic。由于对于 `*byte.Buffer` 时，当其值是 nil 时也满足 io.Writer 这个 interface，赋值给 out 之后，out 并不是 nil，但是调用 Write 方法时，Write 的 receiver 也就是 out 的 dynamic value 是 nil，因而会 panic。

解决方法是改变 main 中的 buf 为 io.Writer。