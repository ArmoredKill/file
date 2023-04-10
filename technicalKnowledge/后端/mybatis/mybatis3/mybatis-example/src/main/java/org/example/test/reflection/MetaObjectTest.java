package org.example.test.reflection;

import org.apache.ibatis.reflection.DefaultReflectorFactory;
import org.apache.ibatis.reflection.MetaObject;
import org.apache.ibatis.reflection.factory.DefaultObjectFactory;
import org.apache.ibatis.reflection.wrapper.DefaultObjectWrapperFactory;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 9:27 2023/4/10
 */
public class MetaObjectTest {

    public static void main(String[] args) {
        SysPortal sysPortal =  new SysPortal(1,"key","title","icon","url",
                "moreurl",2,0,"erpurl");
        MetaObject metaObject = MetaObject.forObject(sysPortal,new DefaultObjectFactory(),
                new DefaultObjectWrapperFactory(),new DefaultReflectorFactory());

        String[] getters = metaObject.getGetterNames();

        for (String g:getters){
            System.out.println("=====================================");
            System.out.println("属性：" + " " + g);
            Object b = metaObject.getValue(g);
            System.out.println("对应值：" + " " + b);
            System.out.println("=====================================");
        }

    }

}
