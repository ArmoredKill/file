@jdk.internal.ValueBased 

如果 **Value-based Classes** 变成值类型，值类型确定在栈上分配后，这个方法目前的机制就会有问题。调用 synchronize(obj) 同步对象，如果 **Value-based Classes** 变成值类型，没有普通对象的对象头，那么无法使用正常的锁膨胀同步机制，同时重量锁 mutex 由于可能值类型对象没有堆上位置也无法使用现有的机制实现。

在 Java 16 之后，如果有这些用法，就会在编译阶段有报警提醒：

```java
Double d = 20.0;
synchronized (d) { ... } // javac warning & HotSpot warning
Object o = d;
synchronized (o) { ... } // HotSpot warning
// -------------------------------------
@jdk.internal.ValueBased
public final class SomeVbc {    
    public SomeVbc() {}

    final String ref = "String";

    void abuseVbc() {

        synchronized(ref) {           // OK
            synchronized (this) {     // WARN
            }
        }
    }
}
```
CompactStrings:

Java 9 对字符串的优化主要集中在字符串存储和处理方面，引入了一项被称为 Compact Strings（紧凑字符串）的改进。Compact Strings 的目标是减少字符串在内存中的占用空间，提高性能和效率。在 Java 8 及之前的版本中，字符串内部使用 char 数组来存储字符数据，并使用额外的 int 型字段记录字符串的偏移量和长度。这种表示方式在包含大量 ASCII 字符的字符串中会造成空间浪费，因为每个字符仍然占用 2 个字节的存储空间。

Java 9 引入了 Compact Strings 的概念，对于仅包含 Latin-1 字符集（即 Unicode 编码范围在 U+0000 至 U+00FF 之间）的字符串，使用字节数组存储数据，每个字符只占用 1 个字节。这样可以大大减少这类字符串的内存占用。对于包含非 Latin-1 字符的字符串，仍然使用 char 数组存储数据，每个字符占用 2 个字节。

Compact Strings 的优化带来了两个主要的好处：

1. 内存占用减少：对于仅包含 Latin-1 字符的字符串，在内存中占用的空间减少一半，从而可以降低内存消耗。
2. 性能提升：减少了字符串的内存占用，可以减少内存的分配和垃圾回收的频率，从而提高了性能和效率。
3. 在 Java 命令行启动时，可以通过使用 -XX:+CompactStrings 参数来开启 Compact Strings。该参数告诉 Java 虚拟机在启动时启用紧凑字符串（Compact Strings）优化。

String的底层实现由char[]改成了byte[]：

因为 JDK 9 开始采用了新的字符串存储方案，对于能以 Latin-1（ISO/IEC 8859-1）编码表示的字符串就以单  存储， 包含其他字符的字符串再转而像以前那样用 UTF-16 编码来存储，靠这种双编码并存的方式减少内存占用，以及提高性能。在 Java 9 之前，JavaScript 的 V8 就已经用类似的方式存储字符串了。

这种存储方式一方面内存占用不再比更高（不少场景比 UTF-8 还低），一方面还能享受到 UTF16 的“伪定长”的优势，处理起来更方便，我个人认为这算是目前很优秀的字符串实现方案了。
