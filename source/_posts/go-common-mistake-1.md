title: Go 常见错误之一：值拷贝和 for 循环中的单一变量
date: 2017-10-24 12:47:05
tags:
- mistake
categories:
- practice
---

在 Go 常见的错误一文中 http://devs.cloudimmunity.com/gotchas-and-common-mistakes-in-go-golang/ 有这么一段代码：

```Go

package main

import (  
    "fmt"
    "time"
)

type field struct {  
    name string
}

func (p *field) print() {  
    fmt.Println(p.name)
}

func main() {  
    data := []field{{"one"},{"two"},{"three"}}

    for _,v := range data {
        go v.print()
    }

    time.Sleep(3 * time.Second)
    //goroutines print: three, three, three
}

```

把 field slice 的类型改为 pointer 结果又不同：

```Go

package main

import (  
    "fmt"
    "time"
)

type field struct {  
    name string
}

func (p *field) print() {  
    fmt.Println(p.name)
}

func main() {  
    data := []*field{{"one"},{"two"},{"three"}}

    for _,v := range data {
        v := v
        go v.print()
    }

    time.Sleep(3 * time.Second)
    //goroutines print: one, two, three
}
```

这两段代码的差异究竟是如何导致结果的不同？

我对上面的代码 for 循环中的部分进行了一下改造，改造之后对应的代码分别是：

slice 是非指针
```Go
    data := []field{{"one"},{"two"},{"three"}}

    for _,v := range data {
        pp := (*field).print
        go pp(&v) //非 pointer
    }
```

 slice 是指针
```Go
    data := []*field{{"one"},{"two"},{"three"}}

    for _,v := range data {
        pp := (*field).print
        go pp(v) // pointer
    }
```

改造之后再去看原来的代码就能看出最明显的差异在 `print` 的这个 method 的 `receiver` 的传递上。

在 Go 中**函数的调用是值拷贝 copy value**，而且**在 for 循环中 v 的变量始终是一个变量**。

如果 v 是 pointer，print 这个 method 接收的是指针的拷贝，for 循环体中每次迭代 v 的 pointer value 都是不同的，所以输出不同。

如果 v 是一个普通的 struct，for 循环体中每次迭代 &v 都是 v 这个变量本身的 pointer，也就是总是指向同一个 field，由于在很大程度上这段代码中的 goroutine 都是在 for 结束之后才执行，而此时 v 将会指向最后一个 field，也就是 `{"three"}`，所以输出相同。


有人说 one、two、three 的随机输出是因为 CPU 是多核的原因导致的，如果改成单核就是顺序输出，这样的说法并不是特别准确。理论上来讲 goroutine 的调度是有一定的随机性的，也就是即使是单核输出也有可能是随机的，只是在运行如此简单的例子时一般机器环境都不会导致这 3 个简单的 goroutine 出现交叉执行。比如可以在 print 输出之前模拟 io 繁忙的来达到即使是单核也可能是随机输出的目的。

```Go
    if rand.Intn(100) > 20 {
        time.Sleep(1 * time.Second)
    }
```

