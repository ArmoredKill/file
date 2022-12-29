package com.cc;

import com.alibaba.fastjson.JSONObject;

import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 *
 * @author Crimosn
 * @version 1.0.0
 * @Date Create in 14:46 2022/11/15
 */
public class AlarStorage {


    private static List<String> alarList = new ArrayList<>();

    private final static String urlAlar = "http://10.249.81.24/FMCSAlertQuery";
//    private final static String urlAlar = "http://localhost:9098/test/html";

//    private static final String path = "F:\\file\\limaoxin";
    private static final String path = "C:\\WinCC_OA_Proj_SMBC\\FMCS_SMBC_OPC1\\data";

    /**
     * 初始化部门配置
     */
    public static void init() {
        try {
            File jsonFile = new File(path + "\\ReportV2\\storage\\deptlist.json");
            FileReader fileReader = new FileReader(jsonFile);
            Reader reader = new InputStreamReader(new FileInputStream(jsonFile),"utf-8");
            int ch = 0;
            StringBuffer sb = new StringBuffer();
            while ((ch = reader.read()) != -1) {
                sb.append((char) ch);
            }
            fileReader.close();
            reader.close();
            alarList = JSONObject.parseArray(sb.toString(),String.class);
            ScheduledStorage.deleteFiles("\\ReportV2\\storage");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    public static void main(String[] args) {
        init();
        // 报警生成页面
        alarList.add("222");
        for (String s:alarList){
            Map<String, Object> map;
            map = getTImeRange(Calendar.DATE, -6);
            String params = "?subsystem=" + s + "&t2Year=" + map.get("t2Year") + "&t2Month=" + map.get("t2Month") +
                    "&t2Day=" + map.get("t2Day") + "&t2Hour=23&t2Minute=59&t2Second=59&t1Year=" +
                    map.get("t1Year") + "&t1Month=" + map.get("t1Month") + "&t1Day=" + map.get("t1Day") +
                    "&t1Hour=00&t1Minute=00&t1Second=00&&alertState=0&filter=*&get=查询报警&timeRange=2";
            System.out.println(urlAlar + params);
            String object = ScheduledStorage.request(urlAlar + params ,new HashMap<>(),"get");
            // 生成的文件信息
            String fileName = s + ".html";
            File file2 = new File(path + "\\alarmreport\\storage\\" + fileName);
            BufferedWriter fooW = null;
            try {
                fooW = new BufferedWriter (new OutputStreamWriter (new FileOutputStream (path + "\\alarmreport\\storage\\" + fileName,true),"UTF-8"));
                fooW.write(object);
                fooW.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            System.out.println(fileName + "生成成功！");
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
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE,-1);
        map.put("t2Year",format.format(c.getTime()).substring(0,4));
        map.put("t2Month",format.format(c.getTime()).substring(5,7));
        map.put("t2Day",format.format(c.getTime()).substring(8,10));
        c.add(type,day);
        map.put("t1Year",format.format(c.getTime()).substring(0,4));
        map.put("t1Month",format.format(c.getTime()).substring(5,7));
        map.put("t1Day",format.format(c.getTime()).substring(8,10));
        return map;
    }
}
