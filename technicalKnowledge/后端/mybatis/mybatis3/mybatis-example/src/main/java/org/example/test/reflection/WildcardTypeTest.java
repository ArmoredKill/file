package org.example.test.reflection;

import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.*;
import java.util.List;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 11:00 2023/3/21
 */
public class WildcardTypeTest {

    public static void main(String[] args) {
        Field[] declaredFields = Wind.class.getDeclaredFields();
        for(Field f:declaredFields){
            Type type = f.getGenericType();
            Type actualTypeArgument = ((ParameterizedType) type).getActualTypeArguments()[0];
            if (actualTypeArgument instanceof WildcardType) {
                WildcardType wildcardType = (WildcardType) actualTypeArgument;
                System.out.println(f.getName() + "类型：" + wildcardType.getTypeName() + "；上限："
                        + wildcardType.getUpperBounds() + "；下限：" + wildcardType.getLowerBounds());
                System.out.println("================");
            }
        }
    }


    class Wind{

        List<? extends OutputStream> lowlist;

        List<? super InputStream> uplist;

    }
}
