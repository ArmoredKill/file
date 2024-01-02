package org.example.test.io;

import org.apache.ibatis.io.ResolverUtil;

import java.util.Collection;
import java.util.Set;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 10:19 2023/4/13
 */
public class ResolverUtilTest {

    public static void main(String[] args) {
        ResolverUtil<Comparable> resolverUtil = new ResolverUtil<>();
        // 在包下查找实现了 Comparable 这个类
        resolverUtil.findImplementations(Comparable.class,"org.example.test.io");
        Set<Class<? extends Comparable>> comparables = resolverUtil.getClasses();
    }
}
