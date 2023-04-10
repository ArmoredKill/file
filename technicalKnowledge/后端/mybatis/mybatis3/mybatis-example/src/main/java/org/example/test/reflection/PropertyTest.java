package org.example.test.reflection;

import org.apache.ibatis.reflection.property.PropertyNamer;
import org.apache.ibatis.reflection.property.PropertyTokenizer;

/**
 * Property 工具集
 *
 * @author
 * @version 1.0.0
 * @Date Create in 15:28 2023/3/28
 */
public class PropertyTest {

    public static void main(String[] args) {
        // PropertyTokenizer
        PropertyTokenizer tokenizer = new PropertyTokenizer("orders[0].iterns[1].name");
        do {
            System.out.println("name:" + tokenizer.getName()
                    + ",indexedName:" + tokenizer.getIndexedName()
                    + ",index:" + tokenizer.getIndex());
            tokenizer = tokenizer.next();
        } while (tokenizer.getIndex() != null);

        // PropertyNamer
        System.out.println(PropertyNamer.isGetter("getIsDeal") + "：" + PropertyNamer.methodToProperty("getIsDeal"));
        System.out.println(PropertyNamer.isGetter("isDeal") + "：" + PropertyNamer.methodToProperty("isDeal"));

        // PropertyCopier

    }
}
