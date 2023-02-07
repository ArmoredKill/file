package org.spring.study.listener;

import org.springframework.boot.availability.AvailabilityChangeEvent;
import org.springframework.boot.availability.ReadinessState;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 监听应用程序可用性
 *
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 15:04 2023/2/6
 */
@Component
public class MyReadinessStateExporter {

    @EventListener
    public void onStateChange(AvailabilityChangeEvent<ReadinessState> event) {
        switch (event.getState()) {
            case ACCEPTING_TRAFFIC:
                // create file /tmp/healthy
                System.out.println("accepting.....");
                break;
            case REFUSING_TRAFFIC:
                // remove file /tmp/healthy
                System.out.println("refusing.....");
                break;
        }
    }

}
