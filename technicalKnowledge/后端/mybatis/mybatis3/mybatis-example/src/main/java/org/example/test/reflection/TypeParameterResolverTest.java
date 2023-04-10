package org.example.test.reflection;

import org.apache.ibatis.reflection.TypeParameterResolver;
import sun.reflect.generics.reflectiveObjects.ParameterizedTypeImpl;

import java.lang.reflect.Field;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 10:50 2023/3/27
 */
public class TypeParameterResolverTest {

    public static void main(String[] args) throws Exception {
        Field field = ClassA.class.getDeclaredField("map");
        System.out.println(field.getGenericType());
        System.out.println(field.getGenericType() instanceof ParameterizedType);

        Type type = TypeParameterResolver.resolveFieldType(field, ParameterizedTypeImpl
                .make(SubClassA.class, new Type[]{Long.class},TypeParameterResolverTest.class));
        System.out.println(type.getClass());

        ParameterizedType p = (ParameterizedType) type;
        System.out.println(p.getRawType());
        System.out.println(p.getOwnerType());
    }

}
