package org.example.test.reflection;

import java.lang.reflect.Field;
import java.lang.reflect.GenericArrayType;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.util.List;
import java.util.Map;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 10:49 2023/3/21
 */
public class GenericArrayTypeTest {

    public static void main(String[] args) {
        Field[] declaredFields = user.class.getDeclaredFields();
        for(Field f:declaredFields){
            if(f.getGenericType() instanceof GenericArrayType){
                GenericArrayType genericType = (GenericArrayType) f.getGenericType();
                System.out.println(f.getName() + "数组元素：" + genericType.getGenericComponentType().getTypeName());
                System.out.println("================");
            }
        }
    }

    class user<T>{

        List<Integer>[] integerList;
        T[] belongs;
    }
}
