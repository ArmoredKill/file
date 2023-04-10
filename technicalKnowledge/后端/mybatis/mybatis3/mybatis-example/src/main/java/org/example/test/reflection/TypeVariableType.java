package org.example.test.reflection;

import java.io.Serializable;
import java.lang.reflect.Type;
import java.lang.reflect.TypeVariable;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 11:09 2023/3/20
 */
public class TypeVariableType<K extends List & Serializable, V>  {

    public static void main(String[] args) {
        TypeVariable[] v = new TypeVariableType().getClass().getTypeParameters();

        for(TypeVariable t:v){
            System.out.println(Arrays.stream(t.getBounds()).map(Type::getTypeName).collect(Collectors.toList()));
            System.out.println(t.getName());
            System.out.println(t.getGenericDeclaration());
            System.out.println("-----------------");
        }
    }

}
