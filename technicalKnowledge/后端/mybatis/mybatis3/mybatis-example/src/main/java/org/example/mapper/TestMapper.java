package org.example.mapper;

import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.EnumTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.example.domain.CatTest;
import org.example.domain.DogTest;
import org.example.domain.Test;

import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 9:41 2023/2/21
 */
@Mapper
@CacheNamespace
public interface TestMapper {

    /**
     * xml定义查询
     *
     * @param test
     * @return
     */
//    @Results(id = "TestResultMap", value = {
//            @Result(column = "id", property = "id", jdbcType = JdbcType.BIGINT, id = true),
//            @Result(column = "type", property = "type", jdbcType = JdbcType.VARCHAR),
//            @Result(column = "other", property = "other", jdbcType = JdbcType.VARCHAR),
//            @Result(column = "an_other", property = "anOther", jdbcType = JdbcType.VARCHAR),
//            @Result(column = "date", property = "date", jdbcType = JdbcType.DATE)
//    })
//    @Select("select id, type, an_other ,other, date from test")
    List<Test> selectList(Test test);

    /**
     * 构造函数映射
     *
     * @return
     */
    @ConstructorArgs(value = {
            @Arg(column = "id", javaType = Integer.class),
            @Arg(column = "other", javaType = String.class),
            @Arg(column = "an_other", javaType = String.class),
            @Arg(column = "date", javaType = Date.class)})
    @Select("select * from test")
    List<Test> selectFull();

    /**
     * 分类型注入实体类
     * @return
     */
    @TypeDiscriminator(column = "type",javaType = String.class,
            cases = {
                @Case(value = "1", type = CatTest.class,results = {@Result(property = "catTest",column = "cat_test")}),
                @Case(value = "2", type = DogTest.class,results = {@Result(property = "dogTest",column = "dog_test")})})
    @Select("SELECT id, type, other, date,cat_test, dog_test FROM test")
    List<Test> selectFull2();

    /**
     * mapkey注释实例
     * @return
     */
    @MapKey("id")
    @Select("select * from test")
    Map<Integer,Test> selectMapKey();

    @Select("SELECT id, type, other, date FROM test where id = #{id}")
    Test selectById(Long id);
}
