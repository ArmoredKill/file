package org.example.test.parsing;

import org.apache.ibatis.parsing.GenericTokenParser;
import org.apache.ibatis.parsing.PropertyParser;
import org.apache.ibatis.parsing.TokenHandler;
import org.w3c.dom.Document;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;

import static org.example.test.parsing.XPathTest.createDocument;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 10:01 2023/3/13
 */
public class GenericTokenParserTest {

    public static void main(String[] args) throws XPathExpressionException, IOException {
        Document doc = createDocument();
        XPathFactory factory = XPathFactory.newInstance();
        XPath xPath = factory.newXPath();
        Properties variables = new Properties();
        variables.load(new FileInputStream(new File("mybatis-example/src/main/java/org/example/test/parsing/test.properties")));
        String result = (String) xPath.evaluate( " //book[@year=2010] /title/text()", doc , XPathConstants.STRING);
        System.out.println(parse(result,variables));
    }

    public static String parse(String string, Properties variables) {
        VariableTokenHandler handler = new VariableTokenHandler(variables,true,":");
        GenericTokenParser parser = new GenericTokenParser("${", "}", handler);
        return parser.parse(string);
    }

    private static class VariableTokenHandler implements TokenHandler {
        private final Properties variables;
        private final boolean enableDefaultValue;
        private final String defaultValueSeparator;

        private VariableTokenHandler(Properties variables,boolean enableDefaultValue, String defaultValueSeparator) {
            this.variables = variables;
            this.enableDefaultValue = enableDefaultValue;
            this.defaultValueSeparator = defaultValueSeparator;
        }

        private String getPropertyValue(String key, String defaultValue) {
            return (variables == null) ? defaultValue : variables.getProperty(key, defaultValue);
        }

        @Override
        public String handleToken(String content) {
            if (variables != null) {
                String key = content;
                if (enableDefaultValue) {
                    final int separatorIndex = content.indexOf(defaultValueSeparator);
                    String defaultValue = null;
                    if (separatorIndex >= 0) {
                        key = content.substring(0, separatorIndex);
                        defaultValue = content.substring(separatorIndex + defaultValueSeparator.length());
                    }
                    if (defaultValue != null) {
                        return variables.getProperty(key, defaultValue);
                    }
                }
                if (variables.containsKey(key)) {
                    return variables.getProperty(key);
                }
            }
            return "${" + content + "}";
        }
    }
}
