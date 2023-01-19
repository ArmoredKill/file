/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */

object Color extends Enumeration {

  // 1.类型别名,建议声明,在 import 时有用
  type Color = Value

  // 2.调用 Value 方法
  val GREEN = Value
  // 3.只传入 id
  val RED = Value(3)
  // 4.只传入值
  val BULE = Value("blue")
  // 5.传入 id 和值
  val YELLOW = Value(5, "yellow")
  // 6. 不传入 id 时,id 为上一个声明变量的 id+1,值默认和变量名相同
  val PINK = Value

}
