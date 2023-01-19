import java.util

import scala.collection.mutable.ArrayBuffer
import scala.collection.{JavaConverters, mutable}

/**
 * @author Crimson
 * @Date Create in 14:19 2023/1/16
 * @version 1.0.0
 */
object scalatojava extends App {
  val element = ArrayBuffer("hadoop", "spark", "storm")
  // Scala 转 Java
  val javaList: util.List[String] = JavaConverters.bufferAsJavaList(element)
  // Java 转 Scala
  val scalaBuffer: mutable.Buffer[String] = JavaConverters.asScalaBuffer(javaList)
  for (elem <- scalaBuffer) {
    println(elem)
  }
}
