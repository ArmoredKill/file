package org.example.test.reflection;

import org.apache.ibatis.reflection.DefaultReflectorFactory;
import org.apache.ibatis.reflection.MetaClass;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 16:36 2023/3/28
 */
public class MetaClassTest {

    public static void main(String[] args) {
        MetaClass metaClass = MetaClass.forClass(ClassA.class, new DefaultReflectorFactory());
        String[] names = metaClass.getGetterNames();
        System.out.print("GetterNames:");
        for (String n:names){
            System.out.print(n + " ");
        }
        System.out.println("");
        System.out.println( "isDefaultConstructor:" + metaClass.hasDefaultConstructor());
        System.out.println(metaClass.findProperty("map"));
        System.out.println(metaClass.findProperty("ma1p"));
    }
}
