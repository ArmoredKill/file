package com.cc;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;

import java.io.*;
import java.util.*;

/**
 * @author Crimson
 * @version 1.0.0
 * @Date Create in 14:11 2022/11/22
 */
public class Test {

    private static Map<String,Map<String,List<String>>> eportList = new LinkedHashMap<>();

    private static String[] system = new String[]{"ReportV2","alarmreport"};

    private static List<String> alarList = new ArrayList<>();

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
                    alarList = JSONObject.parseArray(sb.toString(),String.class);
                }
                ScheduledStorage.deleteFiles("\\" + s + "\\storage");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        // 初始化
        init();
//        Thread.sleep(2000);
//        // 每个系统，统计维度分钟、小时加一个月和一周
//        // 第一层 系统
//        for (String m: eportList.keySet()) {
//            Map<String, List<String>> dpList = eportList.get(m);
//            JSONObject system = new JSONObject();
//            JSONArray systemList = new JSONArray();
//            system.put("text",m);
//            system.put("name",m);
//            for(String s: dpList.keySet()){
//                List<String> d = dpList.get(s);
//                JSONObject first = new JSONObject();
//                JSONArray firstList = new JSONArray();
//                first.put("text",s);
//                first.put("name",s);
//                // 第二层 查询多少时间
//                for (String e:distance) {
//                    JSONObject second = new JSONObject();
//                    Map<String, Object> map;
//                    if ("onemonth".equals(e)) {
//                        // 获取前一个月数据
//                        map = ScheduledStorage.getTImeRange(Calendar.MONTH, -1);
//                        second.put("text","一月趋势图");
//                        map.put("type",types[1]);
//                    } else {
//                        // 获取前七天数据
//                        map = ScheduledStorage.getTImeRange(Calendar.DATE, -7);
//                        second.put("text","一周趋势图");
//                        map.put("type",types[0]);
//                    }
//                    map.put("dpList",d);
//                    // 趋势图
//                    JSONObject res = JSONObject.parseObject(ScheduledStorage.request(urlReport,map,"post"));
//                    Thread.sleep(2000);
//                    if (res != null && res.get("result").toString().equals("ok")){
//                        map.put("dept",s);
//                        map.put("system",m);
//                        map.put("distance",e);
//                        ScheduledStorage.copyHtml(res,map,second);
//                        second.put("flag",true);
//                    }
//                    firstList.add(second);
//                }
//                first.put("nodes",firstList);
//                systemList.add(first);
//                break;
//            }
//            system.put("nodes",systemList);
//            stotage1.add(system);
//        }

        // 报警生成页面
        // subsystem=ME&timeRange=2&t1Day=21&t1Month=11&t1Year=2022&t1Hour=00&t1Minute=00&t1Second=00&t2Day=21&t2Month=11&t2Year=2022
        // &t2Hour=23&t2Minute=59&t2Second=59&alertState=0&filter=*&get=查询报警
        for (String s:alarList){
            Map<String, Object> map;
            map = AlarStorage.getTImeRange(Calendar.DATE, -6);
            String params = "?subsystem=" + s + "&t2Year=" + map.get("t2Year") + "&t2Month=" + map.get("t2Month") +
                    "&t2Day=" + map.get("t2Day") + "&t2Hour=23&t2Minute=59&t2Second=59&t1Year=" +
                    map.get("t1Year") + "&t1Month=" + map.get("t1Month") + "&t1Day=" + map.get("t1Day") +
                    "&t1Hour=00&t1Minute=00&t1Second=00&&alertState=0&filter=*&get=查询报警&timeRange=2";
            System.out.println(urlAlar + params);
            String object = ScheduledStorage.request(urlAlar + params ,new HashMap<>(),"get");
            // 生成的文件信息
            String fileName = s + ".html";
            BufferedWriter fooW = null;
            try {
                fooW = new BufferedWriter (new OutputStreamWriter (new FileOutputStream (path + "\\alarmreport\\storage\\" + fileName,true),"UTF-8"));
                fooW.write(object);
                fooW.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            System.out.println(fileName + "生成成功！");
            break;
        }


    }
}
