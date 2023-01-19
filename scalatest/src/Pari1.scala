/**
 * @author Crimson
 * @Date Create in 9:29 2023/1/17
 * @version 1.0.0
 */
// 使用 <: 符号，限定 T 必须是 Comparable[T]的子类型
class Pari1[T <: Comparable[T]](val first:T, val second:T) {
  // 返回较小的值
  def smaller:T = if (first.compareTo(second) < 0) first else second
}
