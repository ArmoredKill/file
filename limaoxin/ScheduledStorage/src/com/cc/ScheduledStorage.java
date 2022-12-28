package com.cc;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;

import java.io.*;
import java.net.URL;
import java.net.URLConnection;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 *
 * @author Crimosn
 * @version 1.0.0
 * @Date Create in 14:46 2022/11/15
 */
public class ScheduledStorage {
    
    private static Map<String,Map<String,List<String>>> eportList = new LinkedHashMap<>();

    private static String[] system = new String[]{"ReportV2","alarmreport"};

    private static Map<String,List<String>> alarList = new LinkedHashMap<>();

    private static final String[] types = new String[]{"MinuteReport","HourReport"};

    private static final String[] distance = new String[]{"oneweek","onemonth"};

//    private static final String path = "F:\\file\\limaoxin";
    private static final String path = "C:\\WinCC_OA_Proj_SMBC\\FMCS_SMBC_OPC1\\data";

//    private static final String urlReport = "http://localhost:9098/test";
    private static final String urlReport = "http://10.249.81.24/FMCS_SPC";

    private final static String urlAlar = "http://10.249.81.24/FMCSAlertQuery";
//    private final static String urlAlar = "http://localhost:9098/test/html";

    private static JSONArray stotage1 = new JSONArray();

    /**
     * 初始化部门配置
     */
    public static void init() {
        try {
            for (String s:system){
                File jsonFile = new File(path + "\\" + s + "\\storage\\deptlist.json");
                FileReader fileReader = new FileReader(jsonFile);
                Reader reader = new InputStreamReader(new FileInputStream(jsonFile),"utf-8");
                int ch = 0;
                StringBuffer sb = new StringBuffer();
                while ((ch = reader.read()) != -1) {
                    sb.append((char) ch);
                }
                fileReader.close();
                reader.close();
                if (s.equals("ReportV2")){
                    eportList = (Map<String, Map<String, List<String>>>) JSONObject.parse(sb.toString());
                }else {
                    alarList = (Map<String, List<String>>) JSONObject.parse(sb.toString());
                }
                deleteFiles("\\" + s + "\\storage");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 定时任务执行crontab -e java -cp com.cc.ScheduledStorage.jar com.cc.ScheduledStorage
     * @param args
     */
    public static void main(String[] args) throws InterruptedException {
        // 初始化
        init();
        Thread.sleep(2000);
        // 每个系统，统计维度分钟、小时加一个月和一周
        // 第一层 系统
        for (String m: eportList.keySet()) {
            Map<String,List<String>> dpList = eportList.get(m);
            JSONObject system = new JSONObject();
            JSONArray systemList = new JSONArray();
            system.put("text",m);
            system.put("name",m);
            for(String s: dpList.keySet()){
                List<String> d = dpList.get(s);
                JSONObject first = new JSONObject();
                JSONArray firstList = new JSONArray();
                first.put("text",s);
                first.put("name",s);
                // 第二层 查询多少时间
                for (String e:distance) {
                    JSONObject second = new JSONObject();
                    Map<String, Object> map;
                    if ("onemonth".equals(e)) {
                        // 获取前一个月数据
                        map = getTImeRange(Calendar.MONTH, -1);
                        second.put("text","一月趋势图");
                        map.put("type",types[1]);
                    } else {
                        // 获取前七天数据
                        map = getTImeRange(Calendar.DATE, -7);
                        second.put("text","一周趋势图");
                        map.put("type",types[0]);
                    }
                    map.put("dpList",d);
                    // 趋势图
                    JSONObject res = JSONObject.parseObject(request(urlReport,map,"post"));
                    Thread.sleep(2000);
                    if (res != null && res.get("result").toString().equals("ok")){
                        map.put("dept",s);
                        map.put("system",m);
                        map.put("distance",e);
                        copyHtml(res,map,second);
                        second.put("flag",true);
                    }
                    firstList.add(second);
                }
                first.put("nodes",firstList);
                systemList.add(first);
            }
            system.put("nodes",systemList);
            stotage1.add(system);
        }

        // 写入生成的文件信息1
        File file = new File(path + "\\ReportV2\\storage\\storage.json");
        FileWriter fooWriter = null;
        try {
            fooWriter = new FileWriter(file, false);
            fooWriter.write(stotage1.toJSONString());
            fooWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 报警生成页面
        for (String s:alarList.keySet()){
            List<String> system = alarList.get(s);
            for (String d:distance) {
                Map<String, Object> map;
                if ("onemonth".equals(d)) {
                    map = getTImeRange(Calendar.MONTH, -30);
                } else {
                    map = getTImeRange(Calendar.DATE, -7);
                }
                for (String m : system) {
                    String params = "?subsystem=" + m + "&t2Year=" + map.get("t2Year") + "&t2Month=" + map.get("t2Month") +
                            "&t2Day=" + map.get("t2Day") + "&t2Hour=" + map.get("t2Hour") + "&t2Minute=" + map.get("t2Minute") +
                            "&t2Second" + map.get("t2Second") + "&t1Year=" + map.get("t1Year") + "&t1Month=" + map.get("t1Month") +
                            "&t1Day=" + map.get("t1Day") + "&t1Hour=" + map.get("t1Hour") + "&t1Minute=" + map.get("t1Minute") +
                            "&t1Second" + map.get("t1Second") + "&alertState=0&filter=*&get=查询报警&timeRange=2";
                    String object = request(urlAlar + params ,new HashMap<>(),"get");
                    // 生成的文件信息
                    String fileName = s + "-" + m + "-" + d + ".html";
                    File file2 = new File(path + "\\alarmreport\\storage\\" + fileName);
                    FileWriter fooW = null;
                    try {
                        fooW = new FileWriter(file2, false);
                        fooW.write(object);
                        fooW.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    System.out.println(fileName + "生成成功！");
                }
            }
        }


    }

    /**
     * 发起请求请求数据 （json={"dpList":["DA1:F3P1A_3F_CR_MT4_HT.STATE.VAL_IN.VALUE","DA1:F3P1A_3F_CR_MT8_HT.STATE.VAL_IN.VALUE",
     *  "DA1:F3P1B_3F_CR_MT13_HT.STATE.VAL_IN.VALUE","DA1:F3P1A_3F_CR_MT4_TT.STATE.VAL_IN.VALUE","DA1:F3P1A_3F_CR_MT8_TT.STATE.VAL_IN.VALUE",
     *  "DA1:F3P1B_3F_CR_MT13_TT.STATE.VAL_IN.VALUE"],"type":"MinuteReport","startTime":"2022-11-01 18:52:09","endTime":"2022-11-17 18:52:14"}）
     * @param url
     * @param map
     * @return
     */
    public static String request(String url, Map<String, Object> map,String method){
        OutputStreamWriter out = null ;
        BufferedReader in = null;
        StringBuilder result = new StringBuilder();
        try {
            URL realUrl = new URL(url);
            // 打开和URL之间的连接
            URLConnection conn = realUrl.openConnection();
            //设置通用的请求头属性
            conn.setRequestProperty("accept", "*/*");
            conn.setConnectTimeout(3000000);
            conn.setRequestProperty("connection", "Keep-Alive");
            conn.setRequestProperty("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1;SV1)");
            // 发送POST请求必须设置如下两行 否则会抛异常(java.net.ProtocolException: cannot write to a URLConnection if doOutput=false - call setDoOutput(true))
            if (method.equals("post")){
                conn.setDoOutput(true);
                conn.setDoInput(true);
            }
            //添加参数
            if (!map.isEmpty()){
                //获取URLConnection对象对应的输出流并开始发送参数
                out = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
                out.write("json="+JSONObject.toJSONString(map));
                out.flush();
            }
            in = new BufferedReader(new InputStreamReader(conn.getInputStream(),"UTF-8"));
            String line;
            while ((line = in.readLine()) != null) {
                result.append(line);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }finally {// 使用finally块来关闭输出流、输入流
            try {
                if (out != null) {
                    out.close();
                }
                if (in != null) {
                    in.close();
                }
            } catch (IOException ex) {
                ex.printStackTrace();
            }
        }
        return result.toString();
    }

    /**
     * 转移html页面
     * @param jsonObject
     * @param map
     */
    public static void copyHtml(JSONObject jsonObject,Map<String, Object> map, JSONObject third){
        File oldFile = new File(path + "\\ReportV2\\SPC\\" + jsonObject.get("data"));
        String fileName = map.get("system") + "-" + map.get("dept") + "-" + map.get("distance") + "-" + map.get("type") + ".html";
        File newFile = new File(path + "\\ReportV2\\storage\\" + fileName);
        oldFile.renameTo(newFile);
        third.put("name",fileName);
        System.out.println("趋势图文件：" + fileName + "，生成成功！；");
    }

    /**
     * 生成html文件
     *
     * @param jsonObject
     * @param map
     */
    public static void saveExcel(JSONObject jsonObject, Map<String, Object> map) {

    }

    /**
     * 删除指定文件夹内的html文件
     *
     * @param e
     */
    public static void deleteFiles(String e){
        File file = new File(path + e);
        if (file.exists()) {
            File[] fileList = file.listFiles();
            for (File f : fileList) {
                if(f.isFile() && f.getName().indexOf(".html") > 0) {
                    f.delete();
                }
            }
        }
    }

    /**
     * 获取时间区间
     *
     * @param day
     * @return
     */
    public static Map<String,Object> getTImeRange(Integer type , Integer day){
        Map<String,Object> map = new HashMap<String,Object>();
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        Calendar c = Calendar.getInstance();
        map.put("endTime",format.format(c.getTime()));
        c.add(type,day);
        map.put("startTime",format.format(c.getTime()));
        return map;
    }

}
