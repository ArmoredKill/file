package org.example.test;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 11:05 2023/2/27
 */
public class XPathTest {
    public static void main(String[] args) throws Exception{
        DocumentBuilderFactory documentBuilderFactory = DocumentBuilderFactory.newInstance();

        // 开启验证
        documentBuilderFactory.setValidating(true);
        documentBuilderFactory.setNamespaceAware(false);
        documentBuilderFactory.setIgnoringComments(true);
        documentBuilderFactory.setIgnoringElementContentWhitespace(false);
        documentBuilderFactory.setCoalescing(false);
        documentBuilderFactory.setExpandEntityReferences(true);

        // 创建
        DocumentBuilder builder = documentBuilderFactory.newDocumentBuilder();
        builder.setErrorHandler(new ErrorHandler() {
            @Override
            public void warning(SAXParseException exception) throws SAXException {
                System.out.println("warning:" + exception.getMessage());
            }

            @Override
            public void error(SAXParseException exception) throws SAXException {
                System.out.println("error::" + exception.getMessage());
            }

            @Override
            public void fatalError(SAXParseException exception) throws SAXException {
                System.out.println("fatalError::" + exception.getMessage());
            }
        });

        // 将文档加载到Document
        Document doc = builder.parse("mybatis-example/src/main/java/org/example/test/inventory.xml");
        // 创建 XPathFactory
        XPathFactory factory = XPathFactory.newInstance();
        // 创建 XPath 对象
        XPath xPath = factory.newXPath();
        // 编译 XPath 表达式
        XPathExpression expr = xPath.compile("//book[author='Neal Stephenson']/title/text()");
        // 通过 XPath 表达式得到结采，第一个参数指定了 XPath 表达式进行查询的上下文节点，也就是在指定
        // 节点下查找符合 XPath 的节点。 本例中的上下文节点是整个文档；第二个参数指定了 XPath 表达式
        // 的返回类型。
        Object result = expr.evaluate(doc, XPathConstants.NODESET);
        System.out.println("查询作者为 Neal Stephenson 的图书的标题：");
        NodeList nodes= (NodeList) result;
        // 强制类型转换
        for (int i = 0; i < nodes.getLength() ; i++) {
            System.out.println(nodes.item(i).getNodeValue());
        }

        System.out.println("查询1997年之后的图书的标题：");
        nodes = (NodeList)xPath.evaluate( " //book[@year>1997] /title/text ()", doc , XPathConstants.NODESET);
        for(int i  = 0; i < nodes.getLength();i++){
            System. out.println(nodes.item(i).getNodeValue());
        }

        System.out.println("查询 1997 年之后的图书的属性和标题：");
        nodes = (NodeList)xPath.evaluate("//book [@year>1997] /@*|//book [@year>1997] /title/text()", doc , XPathConstants. NODESET);
        for (int i  = 0; i < nodes.getLength(); i++) {
            System. out. println (nodes.item(i).getNodeValue());
        }
    }
}
