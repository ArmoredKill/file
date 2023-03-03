package org.example.domain;

import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 9:42 2023/2/21
 */
@Data
public class Test implements Serializable {

    private Integer id;
    private String type;
    private String other;
    private String anOther;
    private Date date;

    public Test(){

    }

    public Test(Integer id, String other, String anOther, Date date) {
        this.id = id;
        this.other = other;
        this.anOther = anOther;
        this.date = date;
    }

}
