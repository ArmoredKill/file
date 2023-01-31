# @Configuration
Full模式和Lite模式均是针对于Spring配置类而言的，和xml配置文件无关。值得注意的是：判断是Full模式 or Lite模式的前提是，首先你得是个容器组件。
## Lite模式
当@Bean方法在没有使用@Configuration注释的类中声明时，它们被称为在Lite模式下处理。它包括：在@Component中声明的@Bean方法，甚至只是在一个非常普通的类中声明的Bean方法，都被认为是Lite版的配置类。@Bean方法是一种通用的工厂方法（factory-method）机制。
和Full模式的@Configuration不同，Lite模式的@Bean方法不能声明Bean之间的依赖关系。因此，这样的@Bean方法不应该调用其他@Bean方法。每个这样的方法实际上只是一个特定Bean引用的工厂方法(factory-method)，没有任何特殊的运行时语义。
如下case均认为是Lite模式的配置类：
* 类上标注有@Component注解
* 类上标注有@ComponentScan注解
* 类上标注有@Import注解
* 类上标注有@ImportResource注解
* 若类上没有任何注解，但类内存在@Bean方法
在Spring 5.2之后新增，标注有@Configuration(proxyBeanMethods = false)。
优缺点：
* 运行时不再需要给对应类生成CGLIB子类，提高了运行性能，降低了启动时间
* 可以该配置类当作一个普通类使用喽：也就是说@Bean方法 可以是private、可以是final
* 不能声明@Bean之间的依赖，也就是说不能通过方法调用来依赖其它Bean
代码示例：
``` java
@ComponentScan("com.yourbatman.fullliteconfig.liteconfig")
@Configuration
public class AppConfig {
}


@Component
// @Configuration(proxyBeanMethods = false) // 这样也是Lite模式
public class LiteConfig {
 
    @Bean
    public User user() {
        User user = new User();
        user.setName("A哥-lite");
        user.setAge(18);
        return user;
    }
 
 
    @Bean
    private final User user2() {
        User user = new User();
        user.setName("A哥-lite2");
        user.setAge(18);
 
        // 模拟依赖于user实例  看看是否是同一实例
        System.out.println(System.identityHashCode(user()));
        System.out.println(System.identityHashCode(user()));
 
        return user;
    }
 
    public static class InnerConfig {
 
        @Bean
        // private final User userInner() { // 只在lite模式下才好使
        public User userInner() {
            User user = new User();
            user.setName("A哥-lite-inner");
            user.setAge(18);
            return user;
        }
    }
}

public class Application {
 
    public static void main(String[] args) {
        ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
 
        // 配置类情况
        System.out.println(context.getBean(LiteConfig.class).getClass());
        System.out.println(context.getBean(LiteConfig.InnerConfig.class).getClass());
 
        String[] beanNames = context.getBeanNamesForType(User.class);
        for (String beanName : beanNames) {
            User user = context.getBean(beanName, User.class);
            System.out.println("beanName:" + beanName);
            System.out.println(user.getClass());
            System.out.println(user);
            System.out.println("------------------------");
        }
    }
}
结果输出：
2073640037
932257672
class org.example.config.LiteConfig
class org.example.config.LiteConfig$InnerConfig
beanName:userInner
class org.example.bean.User
User(name=A哥-lite-inner, age=18)
------------------------
beanName:user
class org.example.bean.User
User(name=A哥-lite, age=18)
------------------------
beanName:user2
class org.example.bean.User
User(name=A哥-lite2, age=18)
------------------------
```
总结：
* 该模式下，配置类本身不会被CGLIB增强，放进IoC容器内的就是本尊
* 该模式下，对于内部类是没有限制的：可以是Full模式或者Lite模式
* 该模式下，配置类内部不能通过方法调用来处理依赖，否则每次生成的都是一个新实例而并非IoC容器内的单例
* 该模式下，配置类就是一普通类，所以@Bean方法可以使用private/final等进行修饰（static自然也是可以）
## Full模式
在常见的场景中，@Bean方法都会在标注有@Configuration的类中声明，以确保总是使用“Full模式”，这么一来，交叉方法引用会被重定向到容器的生命周期管理，所以就可以更方便的管理Bean依赖。
标注有@Configuration注解的类被称为full模式的配置类。自Spring5.2后改为：标注有@Configuration或者@Configuration(proxyBeanMethods = true)的类被称为Full模式的配置类。
优缺点：
* 可以支持通过常规Java调用相同类的@Bean方法而保证是容器内的Bean，这有效规避了在“Lite模式”下操作时难以跟踪的细微错误。
* 运行时会给该类生成一个CGLIB子类放进容器，有一定的性能、时间开销（这个开销在Spring Boot这种拥有大量配置类的情况下是不容忽视的，这也是为何Spring 5.2新增了proxyBeanMethods属性的最直接原因）
* 正因为被代理了，所以@Bean方法 不可以是private、不可以是final
代码实例：
``` java
@Configuration
public class FullConfig {
 
    @Bean
    public User user() {
        User user = new User();
        user.setName("A哥-lite");
        user.setAge(18);
        return user;
    }
 
 
    @Bean
    protected User user2() {
        User user = new User();
        user.setName("A哥-lite2");
        user.setAge(18);
 
        // 模拟依赖于user实例  看看是否是同一实例
        System.out.println(System.identityHashCode(user()));
        System.out.println(System.identityHashCode(user()));
 
        return user;
    }
 
    public static class InnerConfig {
 
        @Bean
        // private final User userInner() { // 只在lite模式下才好使
        public User userInner() {
            User user = new User();
            user.setName("A哥-lite-inner");
            user.setAge(18);
            return user;
        }
    }
public class Application {
 
    public static void main(String[] args) {
        ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
 
        // 配置类情况
        System.out.println(context.getBean(FullConfig.class).getClass());
        System.out.println(context.getBean(FullConfig.InnerConfig.class).getClass());
 
        String[] beanNames = context.getBeanNamesForType(User.class);
        for (String beanName : beanNames) {
            User user = context.getBean(beanName, User.class);
            System.out.println("beanName:" + beanName);
            System.out.println(user.getClass());
            System.out.println(user);
            System.out.println("------------------------");
        }
    }
}
结果输出：
550668305
550668305
class com.yourbatman.fullliteconfig.fullconfig.FullConfig$$EnhancerBySpringCGLIB$$70a94a63
class com.yourbatman.fullliteconfig.fullconfig.FullConfig$InnerConfig
beanName:userInner
class com.yourbatman.fullliteconfig.User
User{name='A哥-lite-inner', age=18}
------------------------
beanName:user
class com.yourbatman.fullliteconfig.User
User{name='A哥-lite', age=18}
------------------------
beanName:user2
class com.yourbatman.fullliteconfig.User
User{name='A哥-lite2', age=18}
------------------------
```
总结：
* 该模式下，配置类会被CGLIB增强(生成代理对象)，放进IoC容器内的是代理
* 该模式下，对于内部类是没有限制的：可以是Full模式或者Lite模式
* 该模式下，配置类内部可以通过方法调用来处理依赖，并且能够保证是同一个实例，都指向IoC内的那个单例
* 该模式下，@Bean方法不能被private/final等进行修饰（因为方法需要被复写嘛，所以不能私有和final。defualt/protected/public都可以哦），否则启动报错：
# @ConditionalOnProperty
ConditionalOnProperty注解类源码如下：
``` java
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.TYPE, ElementType.METHOD })
@Documented
@Conditional(OnPropertyCondition.class)
public @interface ConditionalOnProperty {

	// 数组，获取对应property名称的值，与name不可同时使用
	String[] value() default {};

	// 配置属性名称的前缀，比如spring.http.encoding
	String prefix() default "";

	// 数组，配置属性完整名称或部分名称
	// 可与prefix组合使用，组成完整的配置属性名称，与value不可同时使用
	String[] name() default {};

	// 可与name组合使用，比较获取到的属性值与havingValue给定的值是否相同，相同才加载配置
	String havingValue() default "";

	// 缺少该配置属性时是否可以加载。如果为true，没有该配置属性时也会正常加载；反之则不会生效
	boolean matchIfMissing() default false;

}
```
# spring部分条件注解
// 执行顺序
@AutoConfigureBefore：在指定的配置类初始化前加载
@AutoConfigureAfter：在指定的配置类初始化后再加载
@AutoConfigureOrder：数越小越先初始化
// 条件配置
@ConditionalOnClass ：classpath中存在该类时起效
@ConditionalOnMissingClass ：classpath中不存在该类时起效
@ConditionalOnBean ：DI容器中存在该类型Bean时起效
@ConditionalOnMissingBean ：DI容器中不存在该类型Bean时起效
@ConditionalOnSingleCandidate ：DI容器中该类型Bean只有一个或@Primary的只有一个时起效
@ConditionalOnExpression ：SpEL表达式结果为true时
@ConditionalOnProperty ：参数设置或者值一致时起效
@ConditionalOnResource ：指定的文件存在时起效
@ConditionalOnJndi ：指定的JNDI存在时起效
@ConditionalOnJava ：指定的Java版本存在时起效
@ConditionalOnWebApplication ：Web应用环境下起效
@ConditionalOnNotWebApplication ：非Web应用环境下起效
@ConfigurationProperties：获取到配置文件数据
@ConditionalOnAvailableEndpoint：当指定的管理端点（译者注：接口地址）可用时加载 bean。如果一个端点被单独启用或使用 management.endpoints.web.exposure.include 暴露出来，都视为可用。
@ConditionalOnEnabledHealthIndicator：仅当健康指示器配置 management.health. .enabled 启用时才加载此健康检测指示器类， 需要指定为具体的值
# Spring Factories
@ComponentScan 注解的作用是扫描 @SpringBootApplication 所在的 Application 类所在的包（basepackage）下所有的 @component 注解（或拓展了 @component 的注解）标记的 bean，并注册到 spring 容器中。
Spring Boot 中不能被默认路径扫描的配置类的方式，有 2 种：
* 在Spring Boot主类上使用@Import注解
* 使用 spring.factories 文件
spring-core 包里定义了 SpringFactoriesLoader 类，这个类实现了检索 META-INF/spring.factories 文件，并获取指定接口的配置的功能。在这个类中定义了两个对外的方法：
* loadFactories 根据接口类获取其实现类的实例，这个方法返回的是对象列表。
* loadFactoryNames 根据接口获取其接口类的名称，这个方法返回的是类名的列表。

