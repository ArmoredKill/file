package org.example.domain;

import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 11:26 2023/2/21
 */
@Setter
@Getter
public class DogTest extends Test{

    private String dogTest;

    public DogTest(Integer id, String other, String anOther, Date date) {
        super(id, other, anOther, date);
    }
}
