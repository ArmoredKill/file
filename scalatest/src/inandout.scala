import scala.io.StdIn

/**
 * @author Crimson
 * @Date Create in 14:07 2023/1/16
 * @version 1.0.0
 */
object inandout extends App{


    val name = StdIn.readLine("Your name: ")
    print("Your age: ")
    val age = StdIn.readInt()
    println(s"Hello, ${name}! Next year, you will be ${age + 1}.")

}
