package org.spring.study;

import org.springframework.boot.ExitCodeGenerator;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 14:45 2023/2/6
 */
@SpringBootApplication
public class SpringStudyApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringStudyApplication.class);
//        // 模拟退出
//        System.exit(SpringApplication.exit(SpringApplication.run(SpringStudyApplication.class, args)));
    }

    @Bean
    public ExitCodeGenerator exitCodeGenerator() {
        return () -> 42;
    }

}
