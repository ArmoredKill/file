package org.example.domain;

import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * @author Crimosn
 * @version 1.0.0
 * @Date Create in 11:24 2023/2/21
 */
@Getter
@Setter
public class CatTest extends Test {

    private String catTest;

    public CatTest(Integer id, String other, String anOther, Date date) {
        super(id, other, anOther, date);
    }
}
