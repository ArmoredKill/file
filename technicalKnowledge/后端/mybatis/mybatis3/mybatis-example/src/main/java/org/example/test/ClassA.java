package org.example.test;

import java.util.Map;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 13:58 2023/2/28
 */
public class ClassA <K , V> {

    protected Map<K,V> map;

    public Map<K, V> getMap() {
        return map;
    }

    public void setMap(Map<K, V> map) {
        this.map = map;
    }
}
