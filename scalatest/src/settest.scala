import scala.collection.immutable.HashSet

/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object settest extends App {

  // 可变 Set
  val mutableSet = new collection.mutable.HashSet[Int]
  // 1.添加元素
  mutableSet.add(1)
  mutableSet.add(2)
  mutableSet.add(3)
  mutableSet.add(3)
  mutableSet.add(4)
  // 2.移除元素
  mutableSet.remove(2)
  // 3.调用 mkString 方法 输出 1,3,4
  println(mutableSet.mkString(","))
  // 4. 获取 Set 中最小元素
  println(mutableSet.min)
  // 5. 获取 Set 中最大元素
  println(mutableSet.max)

  // 不可变 Set
  val immutableSet = new collection.immutable.HashSet[Int]
  val ints: HashSet[Int] = immutableSet+1
  println(ints)

  // 声明有序 Set
  val mutableSet2 = collection.mutable.SortedSet(1, 2, 3, 4, 5)
  val immutableSet2 = collection.immutable.SortedSet(3, 4, 5, 6, 7)
  // 两个 Set 的合集  输出：TreeSet(1, 2, 3, 4, 5, 6, 7)
  println(mutableSet2 ++ immutableSet2)
  // 两个 Set 的交集  输出：TreeSet(3, 4, 5)
  println(mutableSet2 intersect immutableSet2)


}
