/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object tupletest extends App {

  val array01 = Array("hadoop", "spark", "storm")
  val array02 = Array(10, 20, 30)
  // 1.zip 方法得到的是多个 tuple 组成的数组
  val tuples: Array[(String, Int)] = array01.zip(array02)
  // 2.也可以在 zip 后调用 toMap 方法转换为 Map
  val map: Map[String, Int] = array01.zip(array02).toMap
  for (elem <- tuples) { println(elem) }
  for (elem <- map) {println(elem)}
}
