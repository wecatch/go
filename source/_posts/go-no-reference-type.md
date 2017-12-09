title: 严格来说 Go 没有引用类型
date: 2017-08-10 12:50:50
tags:
- 引用类型
categories:
- golang
---

## 什么是引用类型

简单类说就是不同的变量内存地址是一样的，也就是说同一个内存地址有不同的别名。

**code-1**
```python
>>> dd = dict()
>>> c = dd
>>> id(c)
4476836672
>>> id(dd)
4476836672
>>> 
```
`code-1` 中的 Python 代码显示 c 和 dd 两个变量的内存地址都是一样的。

## Immutable type 不是引用类型

Int，string，bool 这些 immutable 类型不会有引用类型

```go
package main

import (
    "fmt"
)

func main() {
    var a, b, c = 0, 0, 0
    fmt.Println(&a) //0xc420072188
    fmt.Println(&b) //0xc4200721b0
    fmt.Println(&c) //0xc4200721b8
    d := a
    fmt.Println(&d) //0xc4200721d0

    var s = "a"
    fmt.Println(&s) //0x1040c108
    s += "b"
    fmt.Println(&s) //0x1040c108
}

```


变量 a 赋值给 d ，d 和 a 的地址不同，字符串 s 二次赋值之后地址没有改变，在 immutable type 中不存在两个变量内存地址是一样的。

## Map 可以在函数内部改变，但是 map 不是引用类型

Go 中函数传参是按值传递，在函数内部无法改变函数外部的值，但是 map 可以，是不是 map 是引用类型。
```go
package main

import (
    "fmt"
)

func main() {

    var m map[int]string = map[int]string{
        0: "0",
        1: "1",
    }
    mm := m
    fmt.Printf("%p\n", &m) //0xc42002a028
    fmt.Printf("%p\n", &mm) //0xc42002a030
    fmt.Println(m) // map[0:0 1:1]
    fmt.Println(mm) //map[1:1 0:0]
    changeMap(m)
    fmt.Printf("%p\n", &m) //0xc42002a028
    fmt.Printf("%p\n", &mm)//0xc42002a030
    fmt.Println(m) //map[2:2 0:0 1:1]
    fmt.Println(mm) //map[0:0 1:1 2:2]
}

func changeMap(mmm map[int]string) {
    mmm[2] = "2"
    fmt.Printf("changeMap func %p\n", mmm) //changeMap func 0xc420014150
}

```
可以明确看到 main 中的 mm 和 m 地址完全不同，调用函数 changeMap 之后，它们的值都发生了改变，在函数 changeMap 内部，参数 mmm 的地址和 m 以及 mm 都不同，证实 map 并不是引用传参。

再一个例子。
```go
package main

import (
    "fmt"
)

func main() {
    var m map[int]string
    makeMap(m)
    fmt.Println(m == nil) //true
}


func makeMap(m map[int]string) {
    m = make(map[int]string)
}

```
如果是引用传参 main 函数中的输出不应该是 true。

## Channel 也是按值传参

```go
package main

import (
    "fmt"
)

func main() {
    c1 := make(chan int)
    fmt.Printf("%p\n", &c1) //0xc42002a038
    go func() {
        changeChan(c1)
    }()

    fmt.Println(<-c1)
}

func changeChan(c chan int) {
    fmt.Printf("changeChan %p\n", &c) //0xc42002a040
    c <- 0
}

```
例子中的 channel 在函数内发生了值传递，但是函数内部和外部的 channel 地址不同。


## Map 不是引用类型，为什么可以在函数内部改变

Go 源代码中显示 https://golang.org/src/runtime/hashmap.go map 底层是一个指向 hmap 的指针，这就可以解释即使函数传参是按值传递，由于传递的是指针的拷贝，指针指向的底层 hmap 并没有改变，所以可以在函数内部改变 map 。


> Go 中没有引用类型


