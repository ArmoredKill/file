package org.example.test.reflection;

import org.apache.ibatis.reflection.TypeParameterResolver;
import sun.reflect.generics.reflectiveObjects.ParameterizedTypeImpl;

import java.lang.reflect.*;
import java.util.List;
import java.util.Map;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 14:07 2023/2/28
 */
public class TestParameterizedType {


    public static void main(String[] args) {
        // ParameterizedType测试类
        Field[] declaredFields = Person.class.getDeclaredFields();
        for(Field f:declaredFields){
            if(f.getGenericType() instanceof ParameterizedType){
                ParameterizedType genericType = (ParameterizedType) f.getGenericType();
                System.out.println(String.format("%s 属性的原生类型为%s,参数类型有",f.getName(),genericType.getRawType()));
                for(Type type : genericType.getActualTypeArguments()){
                    System.out.println(type);
                }
                System.out.println("================");
            }
        }

    }

    class Person {

        List<Integer> integerList;
        Map<String,Integer> belongs;

    }
}
