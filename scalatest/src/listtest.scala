import scala.collection.mutable.ListBuffer

/**
 * @author Crimson
 * @Date Create in 14:47 2023/1/16
 * @version 1.0.0
 */
object listtest extends App {

  val list = List("hadoop", "spark", "storm")

//  // 1.列表是否为空
//  list.isEmpty
//
//  // 2.返回列表中的第一个元素
//  list.head
//
//  // 3.返回列表中除第一个元素外的所有元素 这里输出 List(spark, storm)
//  list.tail
//
//  // 4.tail 和 head 可以结合使用
//  list.tail.head
//
//  // 5.返回列表中除了最后一个元素之外的其他元素；与 tail 相反 这里输出 List(hadoop, spark)
//  list.init
//
//  // 6.返回列表中的最后一个元素 与 head 相反
//  list.last
//
//  // 7.使用下标访问元素
//  list(2)
//
//  // 8.获取列表长度
//  list.length
//
//  // 9. 反转列表
//  list.reverse

  val iterator: Iterator[String] = list.iterator

  while (iterator.hasNext) {
    println(iterator.next)
  }

  val array = Array("10", "20", "30")

  list.copyToArray(array,1)

  println(array.toBuffer)

  val buffer = new ListBuffer[Int]
  // 1.在尾部追加元素
  buffer += 1
  buffer += 2
  // 2.在头部追加元素
  3 +=: buffer
  // 3. ListBuffer 转 List
  val list2: List[Int] = buffer.toList
  println(list2)
}
