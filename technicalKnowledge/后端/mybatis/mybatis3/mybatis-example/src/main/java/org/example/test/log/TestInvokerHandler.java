package org.example.test.log;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * @author
 * @version 1.0.0
 * @Date Create in 10:19 2023/4/12
 */
public class TestInvokerHandler implements InvocationHandler {

    private Object target;

    public TestInvokerHandler(Object target){
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object result = method.invoke(target,args);
        return result;
    }

    public Object gerProxy(){
        return Proxy.newProxyInstance(Thread.currentThread().getContextClassLoader()
                ,target.getClass().getInterfaces(),this);
    }

}
