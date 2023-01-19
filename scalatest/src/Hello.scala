/**
 * @author Crimson
 * @Date Create in 11:30 2023/1/16
 * @version 1.0.0
 */
object Hello extends App {
  val result = {
    val a = 1 + 1; val b = 2 + 2; a + b
  }
  print(result)

  // 1.基本使用  输出[1,9)
  for (n <- 1 until 10) {print(n)}

  // 2.使用多个表达式生成器  输出: 11 12 13 21 22 23 31 32 33
  for (i <- 1 to 3; j <- 1 to 3) print(f"${10 * i + j}%3d")

  // 3.使用带条件的表达式生成器  输出: 12 13 21 23 31 32
  for (i <- 1 to 3; j <- 1 to 3 if i != j) print(f"${10 * i + j}%3d")

  val elements = Array("A", "B", "C", "D", "E")

  for (elem <- elements) {
    val score = elem match {
      case "A" => 10
      case "B" => 20
      case "C" => 30
      case _ => 50
    }
    print(elem + ":" + score + ";")
  }

}
