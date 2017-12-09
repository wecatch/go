title: 新手 Go 程序员的最佳实践
date: 2017-07-30 22:02:22
tags:
- 
categories:
- practice
---

> 无意中在 medium 看到了一篇文章《Best practices for a new Go developer》，读完之后略有启发，摘录文章观点至此共飨，感兴趣读者可以直接阅读原文，原文很长也很散乱。

# 1

工欲善其事必先利其器，真正写用 Go 编写代码之前先准备好你的环境，可以考虑从官方文档 [How to Write Go Code](https://golang.org/doc/code.html)。

Go 提供了非常优秀的工具来保证代码的风格和质量，比如：gofmt，godoc，goimports，学会使用它们。

对于新手来说不要着急一开始就想要完整的 Go 程序，你应该认真熟悉 Go 的基本语义和特性，认真读完 官方的 [Effictive Go](https://golang.org/doc/effective_go.html)

# 2

不要害怕犯错，对于一门新的语言，大家都是平等，即使是用 Go 写过一到两年程序的人也会犯一些低级的错误。

要学会顺势而为，学会用 Go 的方式去写 Go 的程序，比如要遵循 Go conventions，不要像 C 一样在 Go 中总是使用指针。

新手都应该看看这篇文章 http://talks.golang.org/2012/splash.article，它有助于你了解 Go 是如何诞生的，它的哲学理念是什么。


# 3

新手不要一开始就过渡关注 goroutine，channel 这些涉及并发的概念，你有可能滥用 channel 而不知道节制，毕竟 Go 在很多方面都表现的非常节制。

理解 interface，了解它的潜力，学会用组合和 interface 创建健壮的 Go 代码， 它是 Go 最富有天赋的能力之一。

如果你之前使用的其它 object-oriented 语言，暂时忘掉那些关于 OO 的特性和思维，虽然 Go 支持 OO，但 Go 不是基于类的语言，不支持类的继承。

# 4 

Go 是强类型语言，意味着实现非常复杂的系统 API 时有可能会像 Java 或 C++ 一样使用大量的预定义类型，使代码变得脆弱丑陋，这并不是真正的 Go。Go 的 interface 和闭包特性允许我们写出更优雅更通用的实现。

学会高效的使用闭包，为此可以学习一些函数式编程语言的理论，或者学学 Ruby，可以看看 The Well-Grounded Rubyist 这本书，然后尝试在 Go 编程中尝试使用这些知识。

学会测试 Go 程序，学会使用 Go 相关的测试工具 unit testing，beachmarking testing，利用测试不断纠正和提高 Go 程序的质量，可以看看这个 http://github.com/feyeleanor/GoSpeed。

# 5

不要强迫你把过去其它语言的经验带入 Go，每个语言都是不同的，如果你是第一次接触 Go，让自己用一个全新的视角去看待它，也就是你需要尝试从语言的创作者以及社区的角度去理解它。


一开始使用 Go，尽量避免使用 third party library，可能它们能简化你正在做的事情，但从长远角度来看，它们也妨碍了你对这么语言的理解。

从标准库中学习如何写出更好的 Go 代码，比如你可以从 `net/http` package 中学习如何使用 concurrency，也可以去看看  Rob Pike 关于 concurrency 的视频。

# 6

尝试使用 composition 而不是 inheritance，基于 OO 的 inheritance 的思维方式会妨碍你写出优雅的 Go 代码。

拥抱 interface。

并不是所有的都是 object。


> A language that doesn’t affect the way you think about programming, is not worth knowing. — Alan Perlis

如果一门语言没有影响你对编程的思考，这么语言就不值得学习。

# 7

- 保持函数短小，变量名不要太长
- 不要像写其它语言一样写 Go，Go 不是 Java，不是 Python，不是 Ruby。
- 花点时间搞懂 named and unnamed types。
- 学会构建完整的 Go project，并且发布它们。
- Interface 很重要，你应该学会使用它们，很多你遇到的问题都可以用 interface 解决。
- 学习阅读源码是学习 Go 的一种极佳的方式。
- 保持简洁，简洁是 Go 的一个重要特性之一，避免过度工程化。
- 以更小的单元实现你的代码功能，然后组合它们。


# 小结


这时间上有很多朴素的道理，很多人都知道，但是这些道理并没有给知道的人带来什么改变，比如勤奋不一定能成功，还是很多人很勤奋，有了好运气也不一定能成功，还是很多人天天盼望走狗屎运，前者太勤奋了，没有时间思考，后者不知道勤奋，总是抱有幻想。

学习语言也是一样，不要着急实践，要先想一想，看一看，看完之后不能太懒，还要动手练一练。