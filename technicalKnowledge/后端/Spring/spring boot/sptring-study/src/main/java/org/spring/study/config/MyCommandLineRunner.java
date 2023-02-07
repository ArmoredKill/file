package org.spring.study.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * 启动后运行代码
 *
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 15:24 2023/2/6
 */
@Component
public class MyCommandLineRunner implements CommandLineRunner {

    public void run(String... args) throws Exception {
        System.out.println("started after do something");
    }
}
