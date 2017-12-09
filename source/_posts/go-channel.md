title: Go channel 的基础特性
date: 2017-08-03 22:17:33
tags:
- channel
categories:
- advanced
---

> 此篇介绍 go channel

## 什么是 goroutine

> They're called goroutines because the existing terms — threads, coroutines, processes, and so on — convey inaccurate connotations. A goroutine has a simple model: it is a function executing in parallel with other goroutines in the same address space. It is lightweight, costing little more than the allocation of stack space. And the stacks start small, so they are cheap, and grow by allocating (and freeing) heap storage as required.

正如官方所言，goroutine 是一个轻量级的执行单元，相比线程开销更小，完全由 Go 语言负责调度，是 Go 支持并发的核心。开启一个 goroutine 非常简单:


```go
package main
import (
	"fmt"
	"time"
)

func main() {
	go fmt.Println("goroutine message")
	time.Sleep(1) //1
	fmt.Println("main function message")
}
```

 `#1` 的代码是必须的，这是为了让新开启的 goroutine 有机会得到执行，开启一个 goroutine 之后，后续的代码会继续执行，在上面的例子中后续代码执行完毕程序就终止了，而开启的 goroutine 可能还没开始执行。

如果尝试去掉 `#1` 处的代码，程序也可能会正常运行，这是因为恰巧开启的 goroutine 只是简单的执行了一次输出，如果 goroutine 中耗时稍长就会导致只能看到主一句 `main function message` 。 

换句话话说，这里的 `time.sleep` 提供的是一种调度机制，这也是 Go 中 channel 存在的目的：负责消息传递和调度。


## Channel 

Channel 是 Go 中为 goroutine 提供的一种通信机制，channel 是有类型的，而且是有方向的，可以把 channel 类比成 unix 中的 pipe。

```go
i := make(chan int)//int 类型
s := make(chan string)//字符串类型
r := make(<-chan bool)//只读
w := make(chan<- []int)//只写
```

Channel 最重要的作用就是传递消息。

```go
package main
import (
	"fmt"
)

func main() {
	c := make(chan int)
	go func() {
		fmt.Println("goroutine message")
		c <- 1 //1
	}()
	<-c //2
	fmt.Println("main function message")
}
```
例子中声明了一个 int 类型的 channel，在 goroutine 中在代码 `#1` 处向 channel 发送了数据 `1` ，在 main 中 `#2` 处等待数据的接收，如果 c 中没有数据，代码的执行将发生阻塞，直到 c 中数据接收完毕。这是 channel 最简单的用法之一：同步 ，这种类型的 channel 没有设置容量，称之为 **unbuffered channel**。

## unbuffered channel 和 buffered channel

Channel 可以设置容量，表示 channel 允许接收的消息个数，默认的 channel 容量是 0 称为 **unbuffered channel** ，对 unbuffered channel 执行 **读** 操作 value := <-ch 会一直阻塞直到有数据可接收，执行 **写** 操作 ch <- value 也会一直阻塞直到有 goroutine 对 channel 开始执行接收，正因为如此在同一个 goroutine 中使用 unbuffered channel 会造成 deadlock。


```go
package main
import (
	"fmt"
)

func main() {
	c := make(chan int)
	c <- 1
	<-c
	fmt.Println("main function message")
}
```

执行报 `fatal error: all goroutines are asleep - deadlock!` ，读和写相互等待对方从而导致死锁发生。

![来自 www.goinggo.net](https://www.goinggo.net/images/goinggo/Screen+Shot+2014-02-16+at+10.10.54+AM.png)

如果 channel 的容量不是 0，此类 channel 称之为 **buffered channel** ，buffered channel 在消息写入个数 **未达到容量的上限之前不会阻塞** ，一旦写入消息个数超过上限，下次输入将会阻塞，直到 channel 有位置可以再写入。

![来自 www.goinggo.net](https://www.goinggo.net/images/goinggo/Screen+Shot+2014-02-17+at+8.38.15+AM.png)

```go
	package main
	import (
		"fmt"
	)
	
	func main() {
		c := make(chan int, 3)
		go func() {
			for i := 0; i < 4; i++ {
				c <- i
				fmt.Println("write to c ", i)
			}
		}()
	
		for i := 0; i < 4; i++ {
			fmt.Println("reading", <-c)
		}
	}
```


上面的例子会输出：

```go
write to c 0
reading 0
write to c 1
reading 1
write to c 2
reading 2
write to c 3
reading 3
```

根据上文对 buffered channel 的解释，这个例子中 channel `c` 的容量是 3，在写入消息个数不超过 3 时不会阻塞，输出应该是：

```go
write to c 0
write to c 1
write to c 2
reading 0
reading 1
reading 2
write to c 3
reading 3
```

问题在哪里？问题其实是在 `fmt.Println` ，一次输出就导致 goroutine 的执行发生了切换(相当于发生了 IO 阻塞)，因而即使 c 没有发生阻塞 goroutine 也会让出执行，一起来验证一下这个问题。


```go
package main
import (
	"fmt"
	"strconv"
)

func main() {
	c := make(chan int, 3)
	s := make([]string, 8)
	var num int = 0
	go func() {
		for i := 0; i < 4; i++ {
			c <- i
			num++
			v := "inner=>" + strconv.Itoa(num)
			s = append(s, v)
		}
	}()

	for i := 0; i < 4; i++ {
		<-c
		num++
		v := "outer=>" + strconv.Itoa(num)
		s = append(s, v)
	}

	fmt.Println(s)
}
```

这里创建了一个 slice 用来保存 c 进行写入和读取时的执行顺序，num 是用来标识执行顺序的，在没有加入 Println 之前，最终 s 是 [inner=>1 inner=>2 inner=>3 inner=>4 outer=>5 outer=>6 outer=>7 outer=>8] ，输出结果表明 c 达到容量上线之后才会发生阻塞。

相反有输出语句的版本结果则不同：


```go
package main
import (
	"fmt"
	"strconv"
)

func main() {
	c := make(chan int, 3)
	s := make([]string, 8)
	var num int = 0
	go func() {
		for i := 0; i < 4; i++ {
			c <- i
			num++
			v := "inner=>" + strconv.Itoa(num)
			s = append(s, v)
			fmt.Println("write to c ", i)
		}
	}()

	for i := 0; i < 4; i++ {
		num++
		v := "outer=>" + strconv.Itoa(num)
		s = append(s, v)
		fmt.Println("reading", <-c)
	}

	fmt.Println(s)
}
```

[outer=>1 inner=>2 outer=>3 inner=>4 inner=>5 inner=>6 outer=>7 outer=>8] 输出结果能表明两个 goroutine 是交替执行，也就是说 IO 的调用 Println 导致 goroutine 的让出了执行。

## 读取多个 channel 的消息

Go 提供了 select 语句来处理多个 channel 的消息读取。


```go
package main
import (
	"fmt"
	"time"
)

func main() {
	c1 := make(chan string)
	c2 := make(chan string)

	go func() {
		for {
			c1 <- "from 1"
			time.Sleep(time.Second * 2)
		}
	}()

	go func() {
		for {
			c2 <- "from 2"
			time.Sleep(time.Second * 2)
		}
	}()

	go func() {
		for {
			select {
			case msg1 := <-c1:
				fmt.Println(msg1)
			case msg2 := <-c2:
				fmt.Println(msg2)
			}
		}
	}()

	var input string
	fmt.Scanln(&input)

}
```


select 语句可以从多个可读的 channel 中随机选取一个执行，注意是 **随机选取。** 

## Channel 关闭之后

Channel 可以被关闭 `close` ，**channel 关闭之后仍然可以读取**，如果 channel 关闭之前有值写入，关闭之后将依次读取 channel 中的消息，读完完毕之后再次读取将会返回 channel 的类型的 zero value：


```go
package main
import (
	"fmt"
)

func main() {
	c := make(chan int, 3)
	go func() {
		c <- 1
		c <- 2
		c <- 3
		close(c)
	}()

	fmt.Println(<-c)
	fmt.Println(<-c)
	fmt.Println(<-c)
	fmt.Println(<-c)
	fmt.Println(<-c)
	fmt.Println(<-c)
}
```

输出 1 2 3 0 0 0 ，0 是 int channel c 的 zero value。

**被关闭的 channel 可以进行 range 迭代**：


```go
package main
import (
	"fmt"
)

func main() {
	c := make(chan int, 3)
	go func() {
		c <- 1
		c <- 2
		c <- 3
		close(c)
	}()

	for i := range c {
		fmt.Println(i)
	}
}
```


未被关闭的 channel 则不行，如果没有被关闭，range 在输出完 channel 中的消息之后将会阻塞一直等待，从而发生死锁。

## 判断 channel 的关闭
```go
value, ok <- c
```
用来判断 channel 是否关闭，如果 channel 是关闭状态，ok 是 false，value 是 channel 的 zero value，否则 ok 是 true 表示 channel 未关闭，value 表示 channel 中的值。



## 参考资料

- https://www.miek.nl/go
- http://guzalexander.com/2013/12/06/golang-channels-tutorial.html