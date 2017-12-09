title: 如何理解 golang nil
date: 2017-06-11 20:01:41
tags:
- nil
categories:
- basic
---

golang 中的 nil 是不同于其他语言的，为了更好的理解 nil，在此我将尝试一步一步揭示 nil 在 golang 中的一些操作和现象。

## 1. nil 是不能比较的

**code-1** [Play](https://play.golang.org/p/FM7oW794sU) 

```go
package main

import (
    "fmt"
)

func main() {
    fmt.Println(nil==nil)
}
```
code-1 输出

```
tmp/sandbox318449491/main.go:8: invalid operation: nil == nil (operator == not defined on nil)
```

这点和 python 等动态语言是不同的，在 python 中，两个 None 值永远相等。

```python
>>> None == None
True
>>> 
```

从 go 的输出结果不难看出，`==` 对于 nil 来说是一种未定义的操作。

## 2. 默认 nil 是 typed 的

**code-2** [Play](https://play.golang.org/p/PVGa9tCWSs)

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Printf("%T", nil) 
	print(nil)
}

```

code-2 输出

```
tmp/sandbox379579345/main.go:9: use of untyped nil
```

print 的输出时未指定类型的，因而无法输出

## 3. 不同类型 nil 的 address 是一样的

**code-3** [Play](https://play.golang.org/p/YQkFQx1hPi)

```go
package main

import (
	"fmt"
)

func main() {
	var m map[int]string
	var ptr *int
	fmt.Printf("%p", m)
	fmt.Printf("%p", ptr)
}

```

m 和 ptr 的 address 都是 0x0

## 4. 不同类型的 nil 是不能比较的

   **code-4** [Play](https://play.golang.org/p/20q0oe2Iu5)

```go
package main

import (
	"fmt"
)

func main() {
	var m map[int]string
	var ptr *int
	fmt.Printf(m == ptr)
}

```

code-4 输出

```
tmp/sandbox618627491/main.go:10: invalid operation: m == ptr (mismatched types map[int]string and *int)

```

## 5. nil 是 map，slice，pointer，channel，func，interface 的零值

**code-5** [Play](https://play.golang.org/p/VeDuWMU4QR)

```go
package main

import (
	"fmt"
)

func main() {
	var m map[int]string
	var ptr *int
	var c chan int
	var sl []int
	var f func()
	var i interface{}
	fmt.Printf("%#v\n", m)
	fmt.Printf("%#v\n", ptr)
	fmt.Printf("%#v\n", c)
	fmt.Printf("%#v\n", sl)
	fmt.Printf("%#v\n", f)
	fmt.Printf("%#v\n", i)
}
```

code-5 输出

```
map[int]string(nil)
(*int)(nil)
(chan int)(nil)
[]int(nil)
(func())(nil)
<nil>
```

[zero value](https://golang.org/ref/spec#The_zero_value) 是 go 中变量在声明之后但是未初始化被赋予的该类型的一个默认值。

> 正确理解 nil 是正确理解 go 中类型的重要一环，因而 nil 的任何细节在遇到之后都不要错过，要做到相应的记录。