/**
 * @author Crimson
 * @Date Create in 9:25 2023/1/17
 * @version 1.0.0
 */
object ScalaApp extends App {

  // 使用时候你直接指定参数类型，也可以不指定，由程序自动推断
  val pair01 = new Pair("hiebaa",22)
  val pair02 = new Pair[String,Int]("hiihiw",11)

  println(pair01)
  println(pair02)

  val pari1 = new Pari1("abc","acb")
  println(pari1.smaller)
}
