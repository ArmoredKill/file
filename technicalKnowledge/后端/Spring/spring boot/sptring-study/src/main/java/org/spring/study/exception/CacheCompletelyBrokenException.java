package org.spring.study.exception;

import lombok.Data;

/**
 * 应用终端错误
 *
 * @author Crimosn
 * @version 1.0.0
 * @Date Create in 15:10 2023/2/6
 */
@Data
public class CacheCompletelyBrokenException extends RuntimeException {
}
