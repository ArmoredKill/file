package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.domain.Test;
import org.example.mapper.TestMapper;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.List;
import java.util.Map;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 9:51 2023/2/21
 */
@Controller
@RequestMapping("/test")
@RequiredArgsConstructor
public class TestController {
    private final TestMapper testMapper;

    @RequestMapping("/list")
    @ResponseBody
    public List<Test> list(Test test){
        return testMapper.selectList(test);
    }

    @RequestMapping("/map")
    @ResponseBody
    public Map<Integer,Test> map(){
        return testMapper.selectMapKey();
    }

    @RequestMapping("/selectById")
    @ResponseBody
    public Test selectById(Long id){
        return testMapper.selectById(id);
    }
}
