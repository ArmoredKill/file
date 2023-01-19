// 1.使用类型别名导入枚举类
import Color.Color;

/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object Colortest extends App {

  // 2.使用枚举类型,这种情况下需要导入枚举类
  def printColor(color: Color): Unit = {
    println(color.toString)
  }

  // 3.判断传入值和枚举值是否相等
  println(Color.YELLOW.toString == "yellow")
  // 4.遍历枚举类和值
  for (c <- Color.values) println(c.id + ":" + c.toString)
}
