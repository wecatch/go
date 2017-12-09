title: Go 中的面向对象
date: 2017-08-17 13:26:18
tags:
- 面向对象
categories:
- advanced
---

Go 不是基于 class 的语言，但是 Go 提供了强大的类型系统来实现 OO（Object Oriented），关于如何正确使用 OO 的争论网上已经非常多了，在此我们秉承 Go 提供的面向对象机制来实现不同的例子和使用模式，借此了解 Go 中的 OO。


## 使用 embed type 实现继承

Go 中的嵌入类型 `embed type` 本质上是一种 composition，Go 不像其它 OO 语言那样提供基于类的继承，那些继承体现的是 `is-a` 关系，但是 Go 不是。

Go 通过 embed type，可以实现 method 和 field 的复用。

```go

package main

import (
    "fmt"
)

type Person struct {
    name string
    age  int
}

func (p *Person) sayName() {
    fmt.Println(p.name)
}

type Student struct {
    Person
    name string
}

func main() {
    p := Person{name: "C"}
    p.sayName() // #1 C

    s1 := Student{name: "Java"}
    s1.sayName() // #2 此行输出空字符串

    s2 := Student{name: "Java", Person: Person{name: "VB"}}
    s2.sayName()         // #3 VB
    fmt.Println(s2.name) // #4 Java
    fmt.Println(s2.Person.name) //#5 VB
}
```

`Person` 是 `Student` 的 embed type，因而 Student 可以直接使用 Person 的 field 和 method，需要注意的是：

1.Student 中的同名属性可以遮蔽 embed type 的属性，`#4` 的输出
2.Student 虽然可以直接调用 embed type 的 method，但是 method 的 receiver 仍然是 embed type，所以 `#2` 输出为空。
3.直接通过 embed type 继承，embed type 无法获取被嵌入类型的属性，原因由 2 导致。


## 类型组合的强大魔力

Go 支持任意类型的 embed type，当然也包括 interface type，通过组合就可以实现多种不同行为的任意组合，这也是 Go 倡导**以更小的单元实现你的代码功能，然后组合它们**的理念。


```go

// student 行为
type StudentTalk interface {
    talk()
}

// teacher 行为
type TeacherTalk interface {
    say()
}

```
首先定义两个 interface 用来表示不同的行为。


```go

// people 行为
type PeopleTalk interface {
    StudentTalk
    TeacherTalk
}
```

通过 embed type 把定义的两个 interface 组合为新的 interface `PeopleTalk`，此时 PeopleTalk 继承了两个 interface 的 method 集合，也就是 PeopleTalk 拥有了 StudentTalk 和 TeacherTalk 的 method 合集。

```go

type Person struct {
    TeacherTalk
    StudentTalk
}

```
Person 也内嵌了 TeacherTalk 和 StudentTalk，对 Person 来说既可以理解成**继承了两个 interface 的 method 集合**，也可以理解是 Person 拥有**两个类型为 TeacherTalk 和 StudentTalk 的 field**，它们的分别可以被赋值为实现了它们的 struct 的值。


```go
type Student struct{}

func (s *Student) talk() {
    fmt.Println("student talk")
}

type Teacher struct{}

func (t *Teacher) say() {
    fmt.Println("teacher say")
}
```
Struct Student 和 Teacher 分别实现了 StudentTalk 和 TeacherTalk。


```go
func meet(p PeopleTalk) {
    fmt.Println("====>people meet<====")
    meetTeacher(p)
    meetStudent(p)
}

func meetTeacher(ps TeacherTalk) {
    fmt.Println("====>teacher meet<====")
    ps.say()
}

func meetStudent(ps StudentTalk) {
    fmt.Println("====>student meet<====")
    ps.talk()
}

func main() {
    t := Teacher{}
    s := Student{}
    // Person 实现了 PeopleTalk 方法，通过 Teacher 和 Student 实例
    p := Person{TeacherTalk: &t, StudentTalk: &s}
    meet(p)
}

```
上面这段 Go 代码展示了 interface 组合带来的魔力，meet function 的参数是 PeopleTalk，而 Person 的实例 p 由于通过实例 t 和 s 实现了 PeopleTalk 的 method，也就是说 p 可以直接通过 meet 函数传递，**meet 的参数 PeopleTalk**，而且实现了 PeopleTalk 必然实现了 StudentTalk 和 TeacherTalk，因为 PeopleTalk 是由它们组合而成的，进而可以在 meet 函数中可以直接调用 meetTeacher 和 meetStudent，它们各自的参数分别是 TeacherTalk 和 StudentTalk。

