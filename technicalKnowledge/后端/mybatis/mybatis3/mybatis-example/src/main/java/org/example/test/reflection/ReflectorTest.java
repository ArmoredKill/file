package org.example.test.reflection;

import org.apache.ibatis.reflection.Reflector;

/**
 *
 * @author Crimosn
 * @version 1.0.0
 * @Date Create in 11:17 2023/3/16
 */
public class ReflectorTest {

    public static void main(String[] args) {
        Reflector reflector = new Reflector(SysPortal.class);
        System.out.println(reflector);
    }
}
