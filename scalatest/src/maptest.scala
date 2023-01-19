import scala.collection.{JavaConverters, mutable}
import scala.collection.immutable.HashMap

/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object maptest extends App {

  // 初始化一个空 map
  val scores01 = new HashMap[String, Int]
  // 从指定的值初始化 Map（方式一）
  val scores02 = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // 从指定的值初始化 Map（方式二）
  val scores03 = Map(("hadoop", 10), ("spark", 20), ("storm", 30))
  // 得到可变 Map
  val scores04 = scala.collection.mutable.Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)

  val scores = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // 1.获取指定 key 对应的值
  println(scores("hadoop"))
  // 2. 如果对应的值不存在则使用默认值
  println(scores.getOrElse("hadoop01", 100))

  val scores1 = scala.collection.mutable.Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // 1.如果 key 存在则更新
  scores1("hadoop") = 100
  // 2.如果 key 不存在则新增
  scores1("flink") = 40
  // 3.可以通过 += 来进行多个更新或新增操作
  scores1 += ("spark" -> 200, "hive" -> 50)
  // 4.可以通过 -= 来移除某个键和值
  scores1 -= "storm"
  for (elem <- scores1) {println(elem)}

  val scores2 = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  val newScores = scores2 + ("spark" -> 200, "hive" -> 50)
  for (elem <- scores2) {println(elem)}

  val scores3 = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // 1. 遍历键
  for (key <- scores3.keys) { println(key) }
  // 2. 遍历值
  for (value <- scores3.values) { println(value) }
  // 3. 遍历键值对
  for ((key, value) <- scores3) { println(key + ":" + value) }

  val scores4 = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // 1.将 scores 中所有的值扩大 10 倍
  val newScore = for ((key, value) <- scores4) yield (key, value * 10)
  for (elem <- newScore) { println(elem) }
  // 2.将键和值互相调换
  val reversalScore: Map[Int, String] = for ((key, value) <- scores4) yield (value, key)
  for (elem <- reversalScore) { println(elem) }

  // 1.使用 TreeMap,按照键的字典序进行排序
  val scores05 = scala.collection.mutable.TreeMap("B" -> 20, "A" -> 10, "C" -> 30)
  for (elem <- scores01) {println(elem)}
  // 2.使用 LinkedHashMap,按照键值对的插入顺序进行排序
  val scores06 = scala.collection.mutable.LinkedHashMap("B" -> 20, "A" -> 10, "C" -> 30)
  for (elem <- scores02) {println(elem)}

  val scores5 = scala.collection.mutable.TreeMap("B" -> 20, "A" -> 10, "C" -> 30)
  // 1. 获取长度
  println(scores5.size)
  // 2. 判断是否为空
  println(scores5.isEmpty)
  // 3. 判断是否包含特定的 key
  println(scores5.contains("A"))

  val scores6 = Map("hadoop" -> 10, "spark" -> 20, "storm" -> 30)
  // scala map 转 java map
  val javaMap: java.util.Map[String, Int] = JavaConverters.mapAsJavaMap(scores6)
  // java map 转 scala map
  val scalaMap: mutable.Map[String, Int] = JavaConverters.mapAsScalaMap(javaMap)
  for (elem <- scalaMap) {println(elem)}

}
