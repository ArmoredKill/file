/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
// 1. 在 scala 中，类不需要用 public 声明,所有的类都具有公共的可见性
class Person {

  // 2. 声明私有变量,用 var 修饰的变量默认拥有 getter/setter 属性
  private var age = 0

  // 3.如果声明的变量不需要进行初始赋值，此时 Scala 就无法进行类型推断，所以需要显式指明类型
  private var name: String = _


  // 4. 定义方法,应指明传参类型。返回值类型不是必须的，Scala 可以自动推断出来，但是为了方便调用者，建议指明
  def growUp(step: Int): Unit = {
    age += step
  }

  // 5.对于改值器方法 (即改变对象状态的方法),即使不需要传入参数,也建议在声明中包含 ()
  def growUpFix(): Unit = {
    age += 10
  }

  // 6.对于取值器方法 (即不会改变对象状态的方法),不必在声明中包含 ()
  def currentAge: Int = {
    age
  }

  /**
   * 7.不建议使用 return 关键字,默认方法中最后一行代码的计算结果为返回值
   *   如果方法很简短，甚至可以写在同一行中
   */
  def getName: String = name
}

// 伴生对象
object Person {

  def main(args: Array[String]): Unit = {
    // 8.创建类的实例
    val counter = new Person()
    // 9.用 var 修饰的变量默认拥有 getter/setter 属性，可以直接对其进行赋值
    counter.age = 12
    counter.growUp(8)
    counter.growUpFix()
    // 10.用 var 修饰的变量默认拥有 getter/setter 属性，可以直接对其进行取值，输出: 30
    println(counter.age)
    // 输出: 30
    println(counter.currentAge)
    // 输出: null
    println(counter.getName)
  }

}