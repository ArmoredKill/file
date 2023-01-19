import scala.math.ceil

/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object functiontest extends App {

  // 将函数 ceil 赋值给变量 fun,使用下划线 (_) 指明是 ceil 函数但不传递参数
  val fun = ceil _
  println(fun(2.3456))  //输出 3.0

  // 1.匿名函数
  (x: Int) => 3 * x
  // 2.具名函数
  val fun2 = (x: Int) => 3 * x
  // 3.直接使用匿名函数
  val array01 = Array(1, 2, 3).map((x: Int) => 3 * x)
  // 4.使用占位符简写匿名函数
  val array02 = Array(1, 2, 3).map(_ * 3)
  // 5.使用具名函数
  val array03 = Array(1, 2, 3).map(fun2)

  def echo(args: String*): Unit = {
    for (arg <- args) println(arg)
  }
  echo("spark","hadoop","flink")

  def detail(name: String, age: Int): Unit = println(name + ":" + age)
  // 1.按照参数定义的顺序传入
  detail("heibaiying", 12)
  // 2.传递参数的时候指定具体的名称,则不必遵循定义的顺序
  detail(age = 12, name = "heibaiying")

  def detail2(name: String, age: Int = 88): Unit = println(name + ":" + age)
  // 如果没有传递 age 值,则使用默认值
  detail2("heibaiying")
  detail2("heibaiying", 12)

  // 1.定义函数
  def square = (x: Int) => {
    x * x
  }
  // 2.定义高阶函数: 第一个参数是类型为 Int => Int 的函数
  def multi(fun: Int => Int, x: Int) = {
    fun(x) * 100
  }
  // 3.传入具名函数
  println(multi(square, 5)) // 输出 2500
  // 4.传入匿名函数
  println(multi(_ * 100, 5)) // 输出 50000

  // 定义柯里化函数
  def curriedSum(x: Int)(y: Int) = x + y
  println(curriedSum(2)(3)) //输出 5
  // 获取传入值为 10 返回的中间函数 10 + y
  val plus: Int => Int = curriedSum(10)_
  println(plus(3)) //输出值 13
  // 定义柯里化函数
  def curriedSum1(x: Int)(y: Int)(z: String) = x + y + z
  println(curriedSum1(2)(3)("name")) // 输出 5name
}
