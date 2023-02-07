package org.spring.study.controller;

import org.springframework.web.bind.annotation.*;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 9:27 2023/2/7
 */
@RestController
@RequestMapping("/users")
public class MyController {

    @GetMapping("/{userId}")
    public String getUser(@PathVariable Long userId) {
        return "getUser" + userId;
    }

    @GetMapping("/{userId}/customers")
    public String getUserCustomers(@PathVariable Long userId) {
        return "getUserCustomers" + userId;
    }

    @DeleteMapping("/{userId}")
    public String deleteUser(@PathVariable Long userId) {
        return "deleteUser" + userId;
    }
}
