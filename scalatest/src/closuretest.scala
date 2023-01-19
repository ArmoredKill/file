/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object closuretest extends App {

  var more = 10
  // addMore 一个闭包函数:因为其捕获了自由变量 more 从而闭合了该函数字面量
  val addMore = (x: Int) => x + more
}
