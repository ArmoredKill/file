#uses "CtrlHTTP"
// post

string secret_key="b645d880068111ea8f09cf8592eb9fbc";
string ssversion="1";


/*main()
{
  // server:我们当服务，IT当客户端，来请求我们的服务索取数据。拉
   httpServer(0,80,0);
   httpConnect("metadataCB", "/metadata/query","application/json charset=UTF-8"); // app:  /firstExample   application/json
   httpConnect("OnlineDataCB", "/realtime/point/query","application/json charset=UTF-8");
   httpConnect("HistoryDataCB", "/history/point/query","application/json charset=UTF-8");
   httpConnect("RealAlarmCB", "/realtime/alarm/query","application/json charset=UTF-8");
   httpConnect("HistoryAlarmCB", "/history/alarm/query","application/json charset=UTF-8");

}*/

string HistoryAlarmCB(blob content ,string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string version=headerValues[dynContains(headerNames, "version")];
  string timestamp=headerValues[dynContains(headerNames, "timestamp")];
  string sign=headerValues[dynContains(headerNames, "sign")];

  string ssign=cryptoHash(version + (string)timestamp + secret_key);

  if(ssign!=sign)
  {
    DebugN("验证失败",version ,timestamp , sign);
    return weberror(2,"签名异常");
  }
  else
    DebugN("验证成功");

  mapping m;
  string str,sRet;
  string t1,t2;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
  if(!(m.contains("start_time")&&m.contains("end_time")))
  {
    return weberror(1,"缺少参数");
  }

  t1=(string)(time)m["start_time"];
  t2=(string)(time)m["end_time"];
  if(m.contains("point_ids"))
  {
    DebugTN("部分历史告警数据开始");
    sRet=mp_HistoryAlarmCB(m["point_ids"],t1,t2);
    DebugTN("部分历史告警数据结束");
  }
  else
  {
    DebugTN("全量历史告警数据开始");
    sRet=all_HistoryAlarmCB(t1,t2);
    DebugTN("全量历史告警数据结束");
  }
  return  sRet;
}

string RealAlarmCB(blob content ,string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string version=headerValues[dynContains(headerNames, "version")];
  string timestamp=headerValues[dynContains(headerNames, "timestamp")];
  string sign=headerValues[dynContains(headerNames, "sign")];

  string ssign=cryptoHash(version + (string)timestamp + secret_key);

  if(ssign!=sign)
  {
    DebugN("验证失败");
    return weberror(2,"签名异常");
  }
  else
    DebugN("验证成功");


  mapping m;
  string str,sRet;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
  if(!(m.contains("point_ids")))
  {
    return weberror(1,"缺少参数");
  }
  if(dynlen(m["point_ids"])==0)
  {
    sRet="";
  }
  else
  {
    DebugTN("实时报警查询开始");
    sRet=mp_RealAlarmCB(m["point_ids"]);
    DebugTN("实时报警查询结束");
  }
  return  sRet;
}

string OnlineDataCB(blob content ,string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string version=headerValues[dynContains(headerNames, "version")];
  string timestamp=headerValues[dynContains(headerNames, "timestamp")];
  string sign=headerValues[dynContains(headerNames, "sign")];

  string ssign=cryptoHash(version + (string)timestamp + secret_key);

  if(ssign!=sign)
  {
    DebugN("验证失败");
    return weberror(2,"签名异常");
  }
  else
    DebugN("验证成功");

  mapping m;
  string str,sRet;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
  if(dynlen(m["point_ids"])==0)
  {
    sRet="";
  }
  else
  {
    DebugTN("实时数据查询开始",m);
    sRet=mp_OnlineDataCB(m["point_ids"]);
    DebugTN("实时数据查询结束");
  }
  DebugN("ret",sRet);
  return  sRet;
}

string metadataCB(blob content  , string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string version=headerValues[dynContains(headerNames, "version")];
  string timestamp=headerValues[dynContains(headerNames, "timestamp")];
  string sign=headerValues[dynContains(headerNames, "sign")];

  string ssign=cryptoHash(version + (string)timestamp + secret_key);

  if(ssign!=sign)
  {
    DebugN("验证失败");
    return weberror(2,"签名异常");
  }
  else
    DebugN("验证成功");
DebugN("content",content);

  mapping m;
  string str,sRet;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
  DebugN(m["point_ids"]);
  if(m["point_ids"][1]=="*")
  {
    DebugTN("全量基础数据查询开始");
    sRet=all_metadataCB();
    DebugTN("全量基础数据查询结束");
  }
  else if(dynlen(m["point_ids"])==0)
  {
    sRet="";
  }
  else
  {
    DebugTN("部分基础数据查询开始");
    sRet=mp_metadataCB(m["point_ids"]);
    DebugTN("部分基础数据查询结束");
  }
  return  sRet;
}

string HistoryDataCB(blob content ,string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string version=headerValues[dynContains(headerNames, "version")];
  string timestamp=headerValues[dynContains(headerNames, "timestamp")];
  string sign=headerValues[dynContains(headerNames, "sign")];

  string ssign=cryptoHash(version + (string)timestamp + secret_key);

  if(ssign!=sign)
  {
    DebugN("验证失败");
    return weberror(2,"签名异常");
  }
  else
    DebugN("验证成功");


  mapping m;
  string str,sRet;
  string t1,t2;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
  DebugN("历史数据",m);
  if(!(m.contains("start_time")&&m.contains("end_time")))
  {
    return weberror(1,"缺少参数");
  }
  t1=(string)(time)m["start_time"];
  t2=(string)(time)m["end_time"];
  if(m.contains("point_ids"))
  {
    DebugTN("部分历史数据开始");
    sRet=mp_HistoryDataCB(m["point_ids"],t1,t2);
    DebugTN("部分历史数据结束");
  }
  else
  {
    DebugTN("全量历史数据开始");
    sRet=all_HistoryDataCB(t1,t2);
    DebugTN("全量历史数据结束");
  }
  return  sRet;
}

string mp_HistoryAlarmCB(dyn_string ftab,string t1,string t2)
{
  if(!(headerNames.contains("version")&&headerNames.contains("timestamp")&&headerNames.contains("sign")))
  {
    return weberror(1,"缺少参数");
  }
  string from1,from2,from3,from4,from5;
  string query1,query2,query3,query4,query5;
  dyn_dyn_string sql;
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  dyn_anytype dp;
  from1 = "'{";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 = "'{";
  from3 = "'{";
  from4 = "'{";
  from5 = "'{";

  for(int i=1;i<=dynlen(ftab);i++)
  {
    sql[i][1]=ftab[i];
    if(strpos(ftab[i],"_CR_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PEX_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if((strpos(ftab[i],"_PCW_")>0) || (strpos(ftab[i],"_PV_")>0) || (strpos(ftab[i],"_HV_")>0))
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_VOC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_NMHC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_UPW_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GMS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_SDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PLB_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CUS_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GHVAC_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_AMT_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_LK_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PMS_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_FMCS_")>0)
    {
      from5 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_WWT_")>0)
    {
      from5 += ftab[i]+".**,";
    }
  }
  from1 += "}'";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 += "}'";
  from3 += "}'";
  from4 += "}'";
  from5 += "}'";

  //"SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA1:' TIMERANGE("2022.09.09 00:00:00","2022.09.09 08:00:00",1,0) SORT BY 0";
  if(from1 != "'{}'")
  {
  if(strpos(from1,",}")>0) uniStrReplace(from1,",}","}");
  query1 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from1+" REMOTE 'DA1:' TIMERANGE(\""+ t1 +"\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query1,tab1);
}
  if(from2 != "'{}'")
  {
  if(strpos(from2,",}")>0) uniStrReplace(from2,",}","}");
  query2 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from2+" REMOTE 'DA2:' TIMERANGE(\""+ t1 +"\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query2,tab2);
}
  if(from3 != "'{}'")
  {
  if(strpos(from3,",}")>0) uniStrReplace(from3,",}","}");
  query3 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from3+" REMOTE 'DA3:' TIMERANGE(\""+ t1 +"\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query3,tab3);
}
  if(from4 != "'{}'")
  {
  if(strpos(from4,",}")>0) uniStrReplace(from4,",}","}");
  query4 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from4+" REMOTE 'DA4:' TIMERANGE(\""+ t1 +"\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query4,tab4);
}
  if(from5 != "'{}'")
  {
  if(strpos(from5,",}")>0) uniStrReplace(from5,",}","}");
  query5 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from5+" REMOTE 'DA5:' TIMERANGE(\""+ t1 +"\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query5,tab5);
}
  tab=realtime_alarmCB(tab1,tab2,tab3,tab4,tab5);


   mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk,uuid;
  int z;
  z=1;


  if(dynlen(tab)>0)
  {
    //DebugN("dpe数量",dynlen(tab));
    for(int i=1;i<=dynlen(tab);i++)
  {
        uuid=createUuid();
        uniStrReplace(uuid,"{","");
        uniStrReplace(uuid,"}","");
        mPoint["serial_no"]=uuid;
        mPoint["point_id"]=tab[i][1];
        mPoint["msg_type"]=tab[i][2];
        mPoint["alarm_time"]=tab[i][3];
        mPoint["content"]=tab[i][4];
        mPoint["alarm_level"]=tab[i][5];
        mPoint["alarm_type"]=alarmtype(tab[i][6]);
        mPoint["snapshot"]=tab[i][7];
        mPoint["suggestion"]=tab[i][8];

        dynAppend(dmPoints, mPoint);

  }

  //DebugTN("分组完成");


  mapping ret;
  ret["alarms"] = dmPoints;

  string sRet = webRet(ret);//jsonEncode(ret, true);
  //DebugTN("格式化完成");
  //DebugN(ret,sRet);

  return  sRet;
}
  else
  {
    return  weberror(0,"请求成功");
  }

}

string all_HistoryAlarmCB(string t1,string t2)
{
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  string unit;
  dyn_anytype dp,dp1;
  int k=1;
DebugTN("开始");
//SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA1:' TIMERANGE("2022.09.08 00:00:00","2022.09.09 16:12:00",1,0) SORT BY 0
  SQL1 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA1:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL1,tab1);

  SQL2 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA2:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL2,tab2);

  SQL3 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA3:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL3,tab3);

  SQL4 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA4:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL4,tab4);

  SQL5 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F*,CUB*,B*}' REMOTE 'DA5:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL5,tab5);
  DebugTN("查询结束");

  tab=realtime_alarmCB(tab1,tab2,tab3,tab4,tab5);


   mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk,uuid;
  int z;
  z=1;


  if(dynlen(tab)>0)
  {
    //DebugN("dpe数量",dynlen(tab));
    for(int i=1;i<=dynlen(tab);i++)
  {
        uuid=createUuid();
        uniStrReplace(uuid,"{","");
        uniStrReplace(uuid,"}","");
        mPoint["serial_no"]=uuid;
        mPoint["point_id"]=tab[i][1];
        mPoint["msg_type"]=tab[i][2];
        mPoint["alarm_time"]=tab[i][3];
        mPoint["content"]=tab[i][4];
        mPoint["alarm_level"]=tab[i][5];
        mPoint["alarm_type"]=tab[i][6];
        mPoint["snapshot"]=tab[i][7];
        mPoint["suggestion"]=tab[i][8];

        dynAppend(dmPoints, mPoint);

  }

  //DebugTN("分组完成");


  mapping ret;
  ret["alarms"] = dmPoints;

  string sRet = webRet(ret);//jsonEncode(ret, true);
  //DebugTN("格式化完成");
  //DebugN(ret,sRet);

  return  sRet;
}
  else
  {
    return  weberror(0,"请求成功");
  }
}




string mp_RealAlarmCB(dyn_string ftab)
{
  string from1,from2,from3,from4,from5;
  string query1,query2,query3,query4,query5;
  dyn_dyn_string sql;
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  dyn_anytype dp;
  from1 = "'{";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 = "'{";
  from3 = "'{";
  from4 = "'{";
  from5 = "'{";
  for(int i=1;i<=dynlen(ftab);i++)
  {
    sql[i][1]=ftab[i];
    if(strpos(ftab[i],"_CR_")>0)
    {
      from1 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_PEX_")>0)
    {
      from1 += ftab[i]+",";
    }
    else if((strpos(ftab[i],"_PCW_")>0) || (strpos(ftab[i],"_PV_")>0) || (strpos(ftab[i],"_HV_")>0))
    {
      from1 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_VOC_")>0)
    {
      from1 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_NMHC_")>0)
    {
      from1 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_UPW_")>0)
    {
      from1 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_CDS_")>0)
    {
      from2 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_GMS_")>0)
    {
      from2 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_SDS_")>0)
    {
      from2 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_PLB_")>0)
    {
      from3 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_CUS_")>0)
    {
      from3 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_GHVAC_")>0)
    {
      from3 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_AMT_")>0)
    {
      from4 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_LK_")>0)
    {
      from4 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_PMS_")>0)
    {
      from4 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_FMCS_")>0)
    {
      from5 += ftab[i]+",";
    }
    else if(strpos(ftab[i],"_WWT_")>0)
    {
      from5 += ftab[i]+",";
    }
  }
  from1 += "}'";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 += "}'";
  from3 += "}'";
  from4 += "}'";
  from5 += "}'";

  //SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM 'F3P1_3B_CR_test_HT.**' REMOTE 'DA1:'
  if(from1 != "'{}'")
  {
  if(strpos(from1,",}")>0) uniStrReplace(from1,",}","}");
  query1 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from1+" REMOTE 'DA1:'";
  dpQuery(query1,tab1);
}
  if(from2 != "'{}'")
  {
  if(strpos(from2,",}")>0) uniStrReplace(from2,",}","}");
  query2 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from2+" REMOTE 'DA2:'";
  dpQuery(query2,tab2);
}
  if(from3 != "'{}'")
  {
  if(strpos(from3,",}")>0) uniStrReplace(from3,",}","}");
  query3 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from3+" REMOTE 'DA3:'";
  dpQuery(query3,tab3);
}
  if(from4 != "'{}'")
  {
  if(strpos(from4,",}")>0) uniStrReplace(from4,",}","}");
  query4 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from4+" REMOTE 'DA4:'";
  dpQuery(query4,tab4);
}
  if(from5 != "'{}'")
  {
  if(strpos(from5,",}")>0) uniStrReplace(from5,",}","}");
  query5 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM "+from5+" REMOTE 'DA5:'";
  dpQuery(query5,tab5);
}
  tab=realtime_alarmCB(tab1,tab2,tab3,tab4,tab5);


   mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk,uuid;
  int z;
  z=1;


  if(dynlen(tab)>0)
  {
    //DebugN("dpe数量",dynlen(tab));
    for(int i=1;i<=dynlen(tab);i++)
  {
        uuid=createUuid();
        uniStrReplace(uuid,"{","");
        uniStrReplace(uuid,"}","");
        mPoint["serial_no"]=uuid;
        mPoint["point_id"]=tab[i][1];
        mPoint["msg_type"]=tab[i][2];
        mPoint["alarm_time"]=tab[i][3];
        mPoint["content"]=tab[i][4];
        mPoint["alarm_level"]=tab[i][5];
        mPoint["alarm_type"]=alarmtype(tab[i][6]);
        mPoint["snapshot"]=tab[i][7];
        mPoint["suggestion"]=tab[i][8];

        dynAppend(dmPoints, mPoint);

  }

  //DebugTN("分组完成");


  mapping ret;
  ret["alarms"] = dmPoints;

  string sRet = webRet(ret);
  //DebugTN("格式化完成");
  //DebugN(ret,sRet);

  return  sRet;

}
  else
  {
  return  weberror(0,"请求成功");
}
}





string mp_HistoryDataCB(dyn_string ftab,string t1,string t2)
{
  string from1,from2,from3,from4,from5;
  string query1,query2,query3,query4,query5;
  dyn_dyn_string sql;
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  dyn_anytype dp;
  from1 = "'{";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 = "'{";
  from3 = "'{";
  from4 = "'{";
  from5 = "'{";

  for(int i=1;i<=dynlen(ftab);i++)
  {
    sql[i][1]=ftab[i];
    if(strpos(ftab[i],"_CR_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PEX_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if((strpos(ftab[i],"_PCW_")>0) || (strpos(ftab[i],"_PV_")>0) || (strpos(ftab[i],"_HV_")>0))
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_VOC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_NMHC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_UPW_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GMS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_SDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PLB_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CUS_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GHVAC_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_AMT_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_LK_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PMS_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_FMCS_")>0)
    {
      from5 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_WWT_")>0)
    {
      from5 += ftab[i]+".**,";
    }
  }
  from1 += "}'";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 += "}'";
  from3 += "}'";
  from4 += "}'";
  from5 += "}'";

  //"SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA1:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  if(from1 != "'{}'")
  {
  if(strpos(from1,",}")>0) uniStrReplace(from1,",}","}");
  query1 = "SELECT ALL '_online.._value', '_online.._stime' FROM "+from1+" REMOTE 'DA1:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query1,tab1);
}
  if(from2 != "'{}'")
  {
  if(strpos(from2,",}")>0) uniStrReplace(from2,",}","}");
  query2 = "SELECT ALL '_online.._value', '_online.._stime' FROM "+from2+" REMOTE 'DA2:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query2,tab2);
}
  if(from3 != "'{}'")
  {
  if(strpos(from3,",}")>0) uniStrReplace(from3,",}","}");
  query3 = "SELECT ALL '_online.._value', '_online.._stime' FROM "+from3+" REMOTE 'DA3:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query3,tab3);
}
  if(from4 != "'{}'")
  {
  if(strpos(from4,",}")>0) uniStrReplace(from4,",}","}");
  query4 = "SELECT ALL '_online.._value', '_online.._stime' FROM "+from4+" REMOTE 'DA4:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query4,tab4);
}
  if(from5 != "'{}'")
  {
  if(strpos(from5,",}")>0) uniStrReplace(from5,",}","}");
  query5 = "SELECT ALL '_online.._value', '_online.._stime' FROM "+from5+" REMOTE 'DA5:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(query5,tab5);
}
  tab = His_mergeCB(tab1,tab2,tab3,tab4,tab5);



  //提取所有的DP类和DP
  int j=1;
  int x=1;
  dyn_string aa;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if(dynContains(dp,tab[i][6])==0)
    {
      dp[x++]=tab[i][6];
    }

  }



  //按DP类和DP重新组合组
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int pl,z,tl;
  z=1;

  DebugN("dpe数量",dynlen(tab));
  DebugN("dp数量",dynlen(dp));
if(dynlen(tab)>=1)
  {
    mDP["point_id"]=tab[1][6];
    tl = 0;
    for(int i=1;i<=dynlen(tab);i++)
  {
    if(tab[i][6]==dp[z])
      {
        uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["value"]=tab[i][2];
        mPoint["unit"]=tab[i][3];
        mPoint["type"]=tab[i][4];
        mPoint["timestamp"]=UNIXTime(tab[i][5]);

        dynAppend(dmPoints, mPoint);
        tl = tl+1;
      }
  else
  {
    mDP["records"]=dmPoints;
    mDP["total"]=tl;
    z=z+1;

    dynClear(dmPoints);
    dynAppend(points, mDP);

    uniStrReplace(tab[i][1],dp[z]+".","");
    mPoint["name"]=tab[i][1];
    mPoint["value"]=tab[i][2];
    mPoint["unit"]=tab[i][3];
    mPoint["type"]=tab[i][4];
    mPoint["timestamp"]=UNIXTime(tab[i][5]);

    dynAppend(dmPoints, mPoint);
    mDP["point_id"]=tab[i][6];

    tl = 1;
  }
  }

    mDP["records"]=dmPoints;
    mDP["total"]=tl;

    dynClear(dmPoints);
    dynAppend(points, mDP);


  mapping ret;
  ret["points"] = points;

  string sRet = webRet(ret);
  //DebugN(ret,sRet);


  return  sRet; // return string.
}
  else
  {
  return  weberror(0,"请求成功");
}
}

string all_HistoryDataCB(string t1,string t2)
{
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  string unit;
  dyn_anytype dp,dp1;
  int k=1;
DebugTN("开始");
  SQL1 = "SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA1:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL1,tab1);

  SQL2 = "SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA2:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL2,tab2);

  SQL3 = "SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA3:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL3,tab3);

  SQL4 = "SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA4:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL4,tab4);

  SQL5 = "SELECT ALL '_online.._value', '_online.._stime' FROM '{F3*.**,CUB*.**,B*.**}' REMOTE 'DA5:' TIMERANGE(\"" + t1 + "\",\"" + t2 + "\",1,0) SORT BY 0";
  dpQuery(SQL5,tab5);
  DebugTN("查询结束");

  tab = His_mergeCB(tab1,tab2,tab3,tab4,tab5);



  //提取所有的DP类和DP
  int j=1;
  int x=1;
  dyn_string aa;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if(dynContains(dp,tab[i][6])==0)
    {
      dp[x++]=tab[i][6];
    }

  }



  //按DP类和DP重新组合组
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int pl,z,tl;
  z=1;

  DebugN("dpe数量",dynlen(tab));
  DebugN("dp数量",dynlen(dp));
if(dynlen(tab)>0)
  {
    mDP["point_id"]=tab[1][6];
    tl = 0;
    for(int i=1;i<=dynlen(tab);i++)
  {
    if(tab[i][6]==dp[z])
      {
        uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["value"]=tab[i][2];
        mPoint["unit"]=tab[i][3];
        mPoint["type"]=tab[i][4];
        mPoint["timestamp"]=UNIXTime(tab[i][5]);

        dynAppend(dmPoints, mPoint);
        tl = tl+1;
      }
  else
  {
    mDP["records"]=dmPoints;
    mDP["total"]=tl;
    z=z+1;

    dynClear(dmPoints);
    dynAppend(points, mDP);

    uniStrReplace(tab[i][1],dp[z]+".","");
    mPoint["name"]=tab[i][1];
    mPoint["value"]=tab[i][2];
    mPoint["unit"]=tab[i][3];
    mPoint["type"]=tab[i][4];
    mPoint["timestamp"]=UNIXTime(tab[i][5]);

    dynAppend(dmPoints, mPoint);
    mDP["point_id"]=tab[i][6];

    tl = 1;
  }
  }

    mDP["records"]=dmPoints;
    mDP["total"]=tl;

    dynClear(dmPoints);
    dynAppend(points, mDP);


  mapping ret;
  ret["points"] = points;

  string sRet = webRet(ret);
  //DebugN(ret,sRet);


  return  sRet; // return string.
  }
else
  {
  return  weberror(0,"请求成功");
  }
}



string mp_OnlineDataCB(dyn_string ftab)
{
  string from1,from2,from3,from4,from5;
  string query1,query2,query3,query4,query5;
  dyn_dyn_string sql;
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  dyn_anytype dp;
  from1 = "'{";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 = "'{";
  from3 = "'{";
  from4 = "'{";
  from5 = "'{";
  for(int i=1;i<=dynlen(ftab);i++)
  {
    if(strpos(ftab[i],"_CR_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PEX_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if((strpos(ftab[i],"_PCW_")>0) || (strpos(ftab[i],"_PV_")>0) || (strpos(ftab[i],"_HV_")>0))
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_VOC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_NMHC_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_UPW_")>0)
    {
      from1 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GMS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_SDS_")>0)
    {
      from2 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PLB_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_CUS_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_GHVAC_")>0)
    {
      from3 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_AMT_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_LK_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_PMS_")>0)
    {
      from4 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_FMCS_")>0)
    {
      from5 += ftab[i]+".**,";
    }
    else if(strpos(ftab[i],"_WWT_")>0)
    {
      from5 += ftab[i]+".**,";
    }
  }
  from1 += "}'";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 += "}'";
  from3 += "}'";
  from4 += "}'";
  from5 += "}'";

  //SELECT '_offline.._value', '_offline.._stime' FROM '{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}' REMOTE 'DA1:'
  if(from1 != "'{}'")
  {
  if(strpos(from1,",}")>0) uniStrReplace(from1,",}","}");
  query1 = "SELECT '_online.._value', '_online.._stime' FROM "+from1+" REMOTE 'DA1:'";
  dpQuery(query1,tab1);
}
  if(from2 != "'{}'")
  {
  if(strpos(from2,",}")>0) uniStrReplace(from2,",}","}");
  query2 = "SELECT '_online.._value', '_online.._stime' FROM "+from2+" REMOTE 'DA2:'";
  dpQuery(query2,tab2);
}
  if(from3 != "'{}'")
  {
  if(strpos(from3,",}")>0) uniStrReplace(from3,",}","}");
  query3 = "SELECT '_online.._value', '_online.._stime' FROM "+from3+" REMOTE 'DA3:'";
  dpQuery(query3,tab3);
}
  if(from4 != "'{}'")
  {
  if(strpos(from4,",}")>0) uniStrReplace(from4,",}","}");
  query4 = "SELECT '_online.._value', '_online.._stime' FROM "+from4+" REMOTE 'DA4:'";
  dpQuery(query4,tab4);
}
  if(from5 != "'{}'")
  {
  if(strpos(from5,",}")>0) uniStrReplace(from5,",}","}");
  query5 = "SELECT '_online.._value', '_online.._stime' FROM "+from5+" REMOTE 'DA5:'";
  dpQuery(query5,tab5);
}
  tab=Online_mergeCB(tab1,tab2,tab3,tab4,tab5);


  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int z;
  z=1;

  DebugN("dpe数量",dynlen(tab));

if(dynlen(tab)>0)
  {
    for(int i=1;i<=dynlen(tab);i++)
  {
        uniStrReplace(tab[i][2],tab[i][1]+".","");
        mPoint["point_id"]=tab[i][1];
        mPoint["name"]=tab[i][2];
        mPoint["value"]=tab[i][3];
        mPoint["unit"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["timestamp"]=UNIXTime(tab[i][6]);

        dynAppend(dmPoints, mPoint);

  }

  //DebugTN("分组完成");


  mapping ret;
  ret["points"] = dmPoints;

  string sRet = webRet(ret);
  //DebugTN("格式化完成");
  //DebugN(ret,sRet);

  return  sRet;
}
  else
  {
  return  weberror(0,"请求成功");
}
}




string mp_metadataCB(dyn_string ftab)
{
  string from1,from2,from3,from4,from5;
  string query1,query2,query3,query4,query5;
  dyn_dyn_string sql;
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  dyn_anytype dp;
  from1 = "'{";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 = "'{";
  from3 = "'{";
  from4 = "'{";
  from5 = "'{";
  for(int i=1;i<=dynlen(ftab);i++)
  {
    sql[i][1]=ftab[i];
    if(strpos(ftab[i],"_PEX_")>0)
    {
      sql[i][2]="PEX";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_CR_")>0)
    {
      sql[i][2]="CR";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_PCW_")>0 || strpos(ftab[i],"_PV_")>0 || strpos(ftab[i],"_HV_")>0)
    {
      sql[i][2]="PCW";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_VOC_")>0)
    {
      sql[i][2]="VOC";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_NMHC_")>0)
    {
      sql[i][2]="NMHC";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_UPW_")>0)
    {
      sql[i][2]="UPW";
      from1 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from1 += ",";
      }
    }
    else if(strpos(ftab[i],"_CDS_")>0)
    {
      sql[i][2]="CDS";
      from2 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from2 += ",";
      }
    }
    else if(strpos(ftab[i],"_GMS_")>0)
    {
      sql[i][2]="GMS";
      from2 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from2 += ",";
      }
    }
    else if(strpos(ftab[i],"_SDS_")>0)
    {
      sql[i][2]="SDS";
      from2 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from2 += ",";
      }
    }
    else if(strpos(ftab[i],"_PLB_")>0)
    {
      sql[i][2]="PLB";
      from3 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from3 += ",";
      }
    }
    else if(strpos(ftab[i],"_GHVAC_")>0)
    {
      sql[i][2]="GHVAC";
      from3 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from3 += ",";
      }
    }
    else if(strpos(ftab[i],"_CUS_")>0)
    {
      sql[i][2]="CUS";
      from3 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from3 += ",";
      }
    }
    else if(strpos(ftab[i],"_AMT_")>0)
    {
      sql[i][2]="AMT";
      from4 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from4 += ",";
      }
    }
else if(strpos(ftab[i],"_LK_")>0)
    {
      sql[i][2]="LK";
      from4 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from4 += ",";
      }
    }
else if(strpos(ftab[i],"_PSO_")>0)
    {
      sql[i][2]="PSO";
      from4 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from4 += ",";
      }
    }
else if(strpos(ftab[i],"_ILINE_")>0)
    {
      sql[i][2]="ILINE";
      from4 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from4 += ",";
      }
    }
else if(strpos(ftab[i],"_PMS_")>0)
    {
      sql[i][2]="PMS";
      from5 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from5 += ",";
      }
    }
else if(strpos(ftab[i],"_WWT_")>0)
    {
      sql[i][2]="WWT";
      from5 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from5 += ",";
      }
    }
else if(strpos(ftab[i],"_FMCS_")>0)
    {
      sql[i][2]="FMCS";
      from5 += ftab[i];
      if(i!=dynlen(ftab))
      {
        from5 += ",";
      }
    }
}
  from1 += "}'";//'{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}'
  from2 += "}'";
  from3 += "}'";
  from4 += "}'";
  from5 += "}'";

  //SELECT '_offline.._value', '_offline.._stime' FROM '{F3P1A_2F_PEX_AEX_PT_01,F3P1A_2F_PEX_AEX_PT_02,F3P1A_2F_PEX_AEX_PT_03}' REMOTE 'DA1:'
  if(from1 != "'{}'")
  {
  if(strpos(from1,",}")>0) uniStrReplace(from1,",}","}");
  query1 = "SELECT '_online.._value', '_online.._stime' FROM "+from1+" REMOTE 'DA1:'";
  dpQuery(query1,tab1);
}
  if(from2 != "'{}'")
  {
  if(strpos(from2,",}")>0) uniStrReplace(from2,",}","}");
  query2 = "SELECT '_online.._value', '_online.._stime' FROM "+from2+" REMOTE 'DA2:'";
  dpQuery(query2,tab2);
}
  if(from3 != "'{}'")
  {
  if(strpos(from3,",}")>0) uniStrReplace(from3,",}","}");
  query3 = "SELECT '_online.._value', '_online.._stime' FROM "+from3+" REMOTE 'DA3:'";
  dpQuery(query3,tab3);
}
  if(from4 != "'{}'")
  {
  if(strpos(from4,",}")>0) uniStrReplace(from4,",}","}");
  query4 = "SELECT '_online.._value', '_online.._stime' FROM "+from4+" REMOTE 'DA4:'";
  dpQuery(query4,tab4);
}
  if(from5 != "'{}'")
  {
  if(strpos(from5,",}")>0) uniStrReplace(from5,",}","}");
  query5 = "SELECT '_online.._value', '_online.._stime' FROM "+from5+" REMOTE 'DA5:'";
  dpQuery(query5,tab5);
}





  tab = mergeCB(tab1,tab2,tab3,tab4,tab5);
  //DebugN(dynlen(tab),tab);
  int j=1;
  int x=1;
  dyn_string aa;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if(dynContains(dp,tab[i][8])==0)
    {
      dp[x++]=tab[i][8];
    }
  }
  //DebugN(dptype);
  //按DP类和DP重新组合组
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int pl,z;
  z=1;

  DebugN("dpe数量",dynlen(tab));
  DebugN("dp数量",dynlen(dp));

if(dynlen(tab)>=1)
  {
    mDP["point_id"]=tab[1][8];
    mDP["dp_type"]=tab[1][9];
    for(int i=1;i<=dynlen(tab);i++)
  {
    if(tab[i][8]==dp[z])
      {
        uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["desc"]=tab[i][2];
        mPoint["category"]=tab[i][3];
        mPoint["value"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["unit"]=tab[i][6];
        mPoint["timestamp"]=UNIXTime(tab[i][7]);


        dynAppend(dmPoints, mPoint);
      }
  else
  {
    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);
    z=z+1;

    uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["desc"]=tab[i][2];
        mPoint["category"]=tab[i][3];
        mPoint["value"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["unit"]=tab[i][6];
        mPoint["timestamp"]=UNIXTime(tab[i][7]);


    dynAppend(dmPoints, mPoint);
    mDP["point_id"]=tab[i][8];
    mDP["dp_type"]=tab[i][9];

  }
  }
    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);

  //DebugTN("分组完成");


  mapping ret;
  ret["points"] = points;

  string sRet = webRet(ret);
  //DebugTN("格式化完成");
  //DebugN(ret,sRet);

  return  sRet; // return string.
}
  else
  {
  return  weberror(0,"请求成功");
}
}

string all_metadataCB()
{
  dyn_dyn_anytype tab,tab1,tab2,tab3,tab4,tab5,dt;
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  string unit;
  dyn_anytype dp,dp1;
  int k=1;

  SQL1 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA1:'";
  dpQuery(SQL1,tab1);

  SQL2 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA2:'";
  dpQuery(SQL2,tab2);

  SQL3 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA3:'";
  dpQuery(SQL3,tab3);

  SQL4 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA4:'";
  dpQuery(SQL4,tab4);

  SQL5 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA5:'";
  dpQuery(SQL5,tab5);

//提取9个要素,并且合并5个DA服务的表
  tab = mergeCB(tab1,tab2,tab3,tab4,tab5);






  //提取所有的DP类和DP
  int j=1;
  int x=1;
  dyn_string aa;
  dynDynSort(tab,1);
  for(int i=1;i<=dynlen(tab);i++)
  {
    if(dynContains(dp,tab[i][8])==0)
    {
      dp[x++]=tab[i][8];
    }

  }



  //按DP类和DP重新组合组
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int pl,z;
  z=1;

  DebugN("dpe数量",dynlen(tab));
  DebugN("dp数量",dynlen(dp));


    mDP["point_id"]=tab[1][8];
    mDP["dp_type"]=tab[1][9];
    for(int i=1;i<=dynlen(tab);i++)
  {
    if(tab[i][8]==dp[z])
      {
        uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["desc"]=tab[i][2];
        mPoint["category"]=tab[i][3];
        mPoint["value"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["unit"]=tab[i][6];
        mPoint["timestamp"]=UNIXTime(tab[i][7]);

        dynAppend(dmPoints, mPoint);
      }
  else
  {
    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);
    z=z+1;

    uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["desc"]=tab[i][2];
        mPoint["category"]=tab[i][3];
        mPoint["value"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["unit"]=tab[i][6];
        mPoint["timestamp"]=UNIXTime(tab[i][7]);

    dynAppend(dmPoints, mPoint);
    mDP["point_id"]=tab[i][8];
    mDP["dp_type"]=tab[i][9];

  }
  }

    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);



  mapping ret;
  ret["points"] = points;

  string sRet = webRet(ret);
  //DebugN(ret,sRet);


  return  sRet; // return string.

}



//合并表格、提取9个元素、去除多余DPE，基础数据
dyn_dyn_anytype mergeCB(dyn_dyn_anytype tab1, dyn_dyn_anytype tab2, dyn_dyn_anytype tab3, dyn_dyn_anytype tab4, dyn_dyn_anytype tab5)
{
  dyn_dyn_anytype tab,dt;
  int k=1;
  if(dynlen(tab1)>1)
  {
  for(int i=2;i<=dynlen(tab1);i++)
  {
    tab[k][1]=dpSubStr((string)tab1[i][1],DPSUB_DP_EL);
    tab[k][2]=dpGetDescription(tab1[i][1])[1];
    tab[k][4]=format(tab1[i][1],tab1[i][2]);
    tab[k][5]=data_type(tab1[i][1]);
    tab[k][6]=dpGetUnit(tab1[i][1])[1];
    tab[k][7]=(string)tab1[i][3];
    tab[k][8]=dpSubStr(tab1[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab1[i][1]);
    tab[k][3]=DataType(tab1[i][1],tab[k][9]);

    k=k+1;
  }
  }

  if(dynlen(tab2)>1)
  {
  for(int i=2;i<=dynlen(tab2);i++)
  {
    tab[k][1]=dpSubStr((string)tab2[i][1],DPSUB_DP_EL);
    tab[k][2]=dpGetDescription(tab2[i][1])[1];
    tab[k][4]=format(tab2[i][1],tab2[i][2]);
    tab[k][5]=data_type(tab2[i][1]);
    tab[k][6]=dpGetUnit(tab2[i][1])[1];
    tab[k][7]=(string)tab2[i][3];
    tab[k][8]=dpSubStr(tab2[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab2[i][1]);
    tab[k][3]=DataType(tab2[i][1],tab[k][9]);

    k=k+1;
  }
  }

  if(dynlen(tab3)>1)
  {
  for(int i=2;i<=dynlen(tab3);i++)
  {
    tab[k][1]=dpSubStr((string)tab3[i][1],DPSUB_DP_EL);
    tab[k][2]=dpGetDescription(tab3[i][1])[1];
    tab[k][4]=format(tab3[i][1],tab3[i][2]);
    tab[k][5]=data_type(tab3[i][1]);
    tab[k][6]=dpGetUnit(tab3[i][1])[1];
    tab[k][7]=(string)tab3[i][3];
    tab[k][8]=dpSubStr(tab3[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab3[i][1]);
    tab[k][3]=DataType(tab3[i][1],tab[k][9]);

    k=k+1;
  }
  }

  if(dynlen(tab4)>1)
  {
  for(int i=2;i<=dynlen(tab4);i++)
  {
    tab[k][1]=dpSubStr((string)tab4[i][1],DPSUB_DP_EL);
    tab[k][2]=dpGetDescription(tab4[i][1])[1];
    tab[k][4]=format(tab4[i][1],tab4[i][2]);
    tab[k][5]=data_type(tab4[i][1]);
    tab[k][6]=dpGetUnit(tab4[i][1])[1];
    tab[k][7]=(string)tab4[i][3];
    tab[k][8]=dpSubStr(tab4[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab4[i][1]);
    tab[k][3]=DataType(tab4[i][1],tab[k][9]);

    k=k+1;
  }
  }

  if(dynlen(tab5)>1)
  {
  for(int i=2;i<=dynlen(tab5);i++)
  {
    tab[k][1]=dpSubStr((string)tab5[i][1],DPSUB_DP_EL);
    tab[k][2]=dpGetDescription(tab5[i][1])[1];
    tab[k][4]=format(tab5[i][1],tab5[i][2]);
    tab[k][5]=data_type(tab5[i][1]);
    tab[k][6]=dpGetUnit(tab5[i][1])[1];
    tab[k][7]=(string)tab5[i][3];
    tab[k][8]=dpSubStr(tab5[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab5[i][1]);
    tab[k][3]=DataType(tab5[i][1],tab[k][9]);

    k=k+1;
  }
  }



  //删除MINUTE、HOUR值和SUM_ALERT、NOTE;
  int j=1;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if((strpos(tab[i][1],"MINUTE.VALUE")== -1) && (strpos(tab[i][1],"HOUR.VALUE")== -1) && (strpos(tab[i][1],"SUM_ALERT")== -1) && (strpos(tab[i][1],"GENERAL.NOTE")== -1) )
    {
      dt[j++]=tab[i];
    }
  }
  dynClear(tab);
  tab=dt;

  return tab;

}


//合并表格、提取6个元素、去除多余DPE，动态数据
dyn_dyn_anytype Online_mergeCB(dyn_dyn_anytype tab1, dyn_dyn_anytype tab2, dyn_dyn_anytype tab3, dyn_dyn_anytype tab4, dyn_dyn_anytype tab5)
{
  dyn_dyn_anytype tab,dt;
  int k=1;
  if(dynlen(tab1)>1)
  {
  for(int i=2;i<=dynlen(tab1);i++)
  {
    tab[k][1]=dpSubStr(tab1[i][1],DPSUB_DP);
    tab[k][2]=dpSubStr((string)tab1[i][1],DPSUB_DP_EL);
    tab[k][3]=format(tab1[i][1],tab1[i][2]);
    tab[k][4]=dpGetUnit(tab1[i][1])[1];
    tab[k][5]=data_type(tab1[i][1]);
    tab[k][6]=tab1[i][3];

    tab[k][7]=DataType(tab1[i][1],dpTypeName(tab1[i][1]));//数据属性类型1 2 3
    k=k+1;
  }
  }

  if(dynlen(tab2)>1)
  {
  for(int i=2;i<=dynlen(tab2);i++)
  {
    tab[k][1]=dpSubStr(tab2[i][1],DPSUB_DP);
    tab[k][2]=dpSubStr((string)tab2[i][1],DPSUB_DP_EL);
    tab[k][3]=format(tab2[i][1],tab2[i][2]);
    tab[k][4]=dpGetUnit(tab2[i][1])[1];
    tab[k][5]=data_type(tab2[i][1]);
    tab[k][6]=tab2[i][3];

    tab[k][7]=DataType(tab2[i][1],dpTypeName(tab2[i][1]));//数据属性类型1 2 3
    k=k+1;
  }
  }

  if(dynlen(tab3)>1)
  {
  for(int i=2;i<=dynlen(tab3);i++)
  {
    tab[k][1]=dpSubStr(tab3[i][1],DPSUB_DP);
    tab[k][2]=dpSubStr((string)tab3[i][1],DPSUB_DP_EL);
    tab[k][3]=format(tab3[i][1],tab3[i][2]);
    tab[k][4]=dpGetUnit(tab3[i][1])[1];
    tab[k][5]=data_type(tab3[i][1]);
    tab[k][6]=tab3[i][3];

    tab[k][7]=DataType(tab3[i][1],dpTypeName(tab3[i][1]));//数据属性类型1 2 3
    k=k+1;
  }
  }

  if(dynlen(tab4)>1)
  {
  for(int i=2;i<=dynlen(tab4);i++)
  {
    tab[k][1]=dpSubStr(tab4[i][1],DPSUB_DP);
    tab[k][2]=dpSubStr((string)tab4[i][1],DPSUB_DP_EL);
    tab[k][3]=format(tab4[i][1],tab4[i][2]);
    tab[k][4]=dpGetUnit(tab4[i][1])[1];
    tab[k][5]=data_type(tab4[i][1]);
    tab[k][6]=tab4[i][3];

    tab[k][7]=DataType(tab4[i][1],dpTypeName(tab4[i][1]));//数据属性类型1 2 3
    k=k+1;
  }
  }

  if(dynlen(tab5)>1)
  {
  for(int i=2;i<=dynlen(tab5);i++)
  {
    tab[k][1]=dpSubStr(tab5[i][1],DPSUB_DP);
    tab[k][2]=dpSubStr((string)tab5[i][1],DPSUB_DP_EL);
    tab[k][3]=format(tab5[i][1],tab5[i][2]);
    tab[k][4]=dpGetUnit(tab5[i][1])[1];
    tab[k][5]=data_type(tab5[i][1]);
    tab[k][6]=tab5[i][3];

    tab[k][7]=DataType(tab5[i][1],dpTypeName(tab5[i][1]));//数据属性类型1 2 3
    k=k+1;
  }
  }


  //删除MINUTE、HOUR值和SUM_ALERT、NOTE,以及只要动态数据;
  int j=1;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if((strpos(tab[i][1],"MINUTE.VALUE")== -1) && (strpos(tab[i][1],"HOUR.VALUE")== -1) && (strpos(tab[i][1],"SUM_ALERT")== -1) && (strpos(tab[i][1],"GENERAL.NOTE")== -1) && tab[i][7] == 2 )
    {
      dt[j++]=tab[i];
    }
  }
  dynClear(tab);
  tab=dt;

  return tab;

}

string format(string dpe,anytype value)
{
  string a;
  langString form;
  form=dpGetFormat(dpe);
  if(form[1]=="" || value==FALSE ||  value==TRUE)
  {
    return (string)value;
  }
  else
  {
    sprintf(a,form[1],value);
    return a;
  }
  DebugN(dpe,value,a);
}


string data_type(string dpe)
{
  int t;
  t=dpElementType(dpe);
  if(t==22)
  {
    return "float";
  }
  else if(t==21)
    {
    return "int";
  }
  else if(t==25)
    {
    return "string";
  }
  else if(t==23)
    {
    return "bool";
  }
  else
    {
    return "NA";
  }
}

int DataType(string dpe,string dptpye)
{
  if(strpos(dpe,"ERROR")>0 || strpos(dpe,"ALM")>0 || strpos(dpe,".TRO")>0 || (strpos(dpe,".DI")>0 && dptpye=="F3P1_F2_CDS_LK_ALM"))
  {
    return 3;
  }
  else if((strpos(dpe,"SEGMENT")>0 || strpos(dpe,"CONFIG")>0)&&(strpos(dpe,".CONFIG.SELECT_VAL")<0))
  {
    return 1;
  }
  else if(strpos(dpe,"MINUTE.VALUE")>0 || strpos(dpe,"HOUR.VALUE")>0 || strpos(dpe,"SUM_ALERT")>0  || strpos(dpe,"GENERAL.NOTE")>0)
  {
    return 0;
  }
  else
  {
    return 2;
  }
}

//合并表格、提取9个元素、去除多余DPE，基础数据
dyn_dyn_anytype His_mergeCB(dyn_dyn_anytype tab1, dyn_dyn_anytype tab2, dyn_dyn_anytype tab3, dyn_dyn_anytype tab4, dyn_dyn_anytype tab5)
{
  dyn_dyn_anytype tab,dt;
  int k=1;
  if(dynlen(tab1)>1)
  {
  for(int i=2;i<=dynlen(tab1);i++)
  {
    tab[k][1]=dpSubStr((string)tab1[i][1],DPSUB_DP_EL);
    tab[k][2]=format(tab1[i][1],tab1[i][2]);
    tab[k][3]=dpGetUnit(tab1[i][1])[1];
    tab[k][4]=data_type(tab1[i][1]);
    tab[k][5]=(int)tab1[i][3];

    tab[k][6]=dpSubStr(tab1[i][1],DPSUB_DP);
    tab[k][7]=DataType(tab1[i][1],dpTypeName(tab1[i][1]));//数据属性类型1 2 3

    k=k+1;
  }
  }

 if(dynlen(tab2)>1)
  {
  for(int i=2;i<=dynlen(tab2);i++)
  {
    tab[k][1]=dpSubStr((string)tab2[i][1],DPSUB_DP_EL);
    tab[k][2]=format(tab2[i][1],tab2[i][2]);
    tab[k][3]=dpGetUnit(tab2[i][1])[1];
    tab[k][4]=data_type(tab2[i][1]);
    tab[k][5]=(int)tab2[i][3];

    tab[k][6]=dpSubStr(tab2[i][1],DPSUB_DP);
    tab[k][7]=DataType(tab2[i][1],dpTypeName(tab2[i][1]));//数据属性类型1 2 3

    k=k+1;
  }
  }

  if(dynlen(tab3)>1)
  {
  for(int i=2;i<=dynlen(tab3);i++)
  {
    tab[k][1]=dpSubStr((string)tab3[i][1],DPSUB_DP_EL);
    tab[k][2]=format(tab3[i][1],tab3[i][2]);
    tab[k][3]=dpGetUnit(tab3[i][1])[1];
    tab[k][4]=data_type(tab3[i][1]);
    tab[k][5]=(int)tab3[i][3];

    tab[k][6]=dpSubStr(tab3[i][1],DPSUB_DP);
    tab[k][7]=DataType(tab3[i][1],dpTypeName(tab3[i][1]));//数据属性类型1 2 3

    k=k+1;
  }
  }

  if(dynlen(tab4)>1)
  {
  for(int i=2;i<=dynlen(tab4);i++)
  {
    tab[k][1]=dpSubStr((string)tab4[i][1],DPSUB_DP_EL);
    tab[k][2]=format(tab4[i][1],tab4[i][2]);
    tab[k][3]=dpGetUnit(tab4[i][1])[1];
    tab[k][4]=data_type(tab4[i][1]);
    tab[k][5]=(int)tab4[i][3];

    tab[k][6]=dpSubStr(tab4[i][1],DPSUB_DP);
    tab[k][7]=DataType(tab4[i][1],dpTypeName(tab4[i][1]));//数据属性类型1 2 3

    k=k+1;
  }
  }

  if(dynlen(tab5)>1)
  {
  for(int i=2;i<=dynlen(tab5);i++)
  {
    tab[k][1]=dpSubStr((string)tab5[i][1],DPSUB_DP_EL);
    tab[k][2]=format(tab5[i][1],tab5[i][2]);
    tab[k][3]=dpGetUnit(tab5[i][1])[1];
    tab[k][4]=data_type(tab5[i][1]);
    tab[k][5]=(int)tab5[i][3];

    tab[k][6]=dpSubStr(tab5[i][1],DPSUB_DP);
    tab[k][7]=DataType(tab5[i][1],dpTypeName(tab5[i][1]));//数据属性类型1 2 3

    k=k+1;
  }
  }




  //删除MINUTE、HOUR值和SUM_ALERT、NOTE;
  int j=1;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if((strpos(tab[i][1],"MINUTE.VALUE")== -1) && (strpos(tab[i][1],"HOUR.VALUE")== -1) && (strpos(tab[i][1],"SUM_ALERT")== -1) && (strpos(tab[i][1],"GENERAL.NOTE")== -1) && tab[i][7] == 2)//DataType(tab5[i][1],dpTypeName(tab5[i][1]));
    {
      dt[j++]=tab[i];
    }
  }
  dynClear(tab);
  tab=dt;

  return tab;

}

dyn_dyn_anytype realtime_alarmCB(dyn_dyn_anytype tab1,dyn_dyn_anytype tab2,dyn_dyn_anytype tab3,dyn_dyn_anytype tab4,dyn_dyn_anytype tab5)
{
  dyn_dyn_anytype tab,dt;
  int k=1;
  if(dynlen(tab1)>1)
  {
  for(int i=2;i<=dynlen(tab1);i++)
  {
    tab[k][1]=dpSubStr(tab1[i][1],DPSUB_DP);
    if(tab1[i][3])
    {
      tab[k][2]=1;
    }
    else
    {
      tab[k][2]=2;
    }
    tab[k][3]=UNIXTime(tab1[i][2]);
    tab[k][4]=tab1[i][4][1];
    if(tab1[i][5][1]=="一级报警")
    {
      tab[k][5]=80;
    }
    else if(tab1[i][5][1]=="二级报警")
    {
      tab[k][5]=60;
    }
    else if(tab1[i][5][1]=="三级报警")
    {
      tab[k][5]=40;
    }
    else
    {
      tab[k][5]=10;
    }
    tab[k][6]=tab1[i][5][1];

    tab[k][7]=(string)tab1[i][6];
    tab[k][8]="NA";
    tab[k][9]=dpSubStr((string)tab1[i][1],DPSUB_DP_EL);
    k=k+1;
  }
  }

  if(dynlen(tab2)>1)
  {
  for(int i=2;i<=dynlen(tab2);i++)
  {
    tab[k][1]=dpSubStr(tab2[i][1],DPSUB_DP);
    if(tab2[i][3])
    {
      tab[k][2]=1;
    }
    else
    {
      tab[k][2]=2;
    }
    tab[k][3]=UNIXTime(tab2[i][2]);
    tab[k][4]=tab2[i][4][1];
    if(tab2[i][5][1]=="一级报警")
    {
      tab[k][5]=80;
    }
    else if(tab2[i][5][1]=="二级报警")
    {
      tab[k][5]=60;
    }
    else if(tab2[i][5][1]=="三级报警")
    {
      tab[k][5]=40;
    }
    else
    {
      tab[k][5]=10;
    }
    tab[k][6]=tab2[i][5][1];

    tab[k][7]=(string)tab2[i][6];
    tab[k][8]="NA";
    tab[k][9]=dpSubStr((string)tab2[i][1],DPSUB_DP_EL);
    k=k+1;
  }
  }

  if(dynlen(tab3)>1)
  {
  for(int i=2;i<=dynlen(tab3);i++)
  {
    tab[k][1]=dpSubStr(tab3[i][1],DPSUB_DP);
    if(tab3[i][3])
    {
      tab[k][2]=1;
    }
    else
    {
      tab[k][2]=2;
    }
    tab[k][3]=UNIXTime(tab3[i][2]);
    tab[k][4]=tab3[i][4][1];
    if(tab3[i][5][1]=="一级报警")
    {
      tab[k][5]=80;
    }
    else if(tab3[i][5][1]=="二级报警")
    {
      tab[k][5]=60;
    }
    else if(tab3[i][5][1]=="三级报警")
    {
      tab[k][5]=40;
    }
    else
    {
      tab[k][5]=10;
    }
    tab[k][6]=tab3[i][5][1];

    tab[k][7]=(string)tab3[i][6];
    tab[k][8]="NA";
    tab[k][9]=dpSubStr((string)tab3[i][1],DPSUB_DP_EL);
    k=k+1;
  }
  }

  if(dynlen(tab4)>1)
  {
  for(int i=2;i<=dynlen(tab4);i++)
  {
    tab[k][1]=dpSubStr(tab4[i][1],DPSUB_DP);
    if(tab4[i][3])
    {
      tab[k][2]=1;
    }
    else
    {
      tab[k][2]=2;
    }
    tab[k][3]=UNIXTime(tab4[i][2]);
    tab[k][4]=tab4[i][4][1];
    if(tab4[i][5][1]=="一级报警")
    {
      tab[k][5]=80;
    }
    else if(tab4[i][5][1]=="二级报警")
    {
      tab[k][5]=60;
    }
    else if(tab4[i][5][1]=="三级报警")
    {
      tab[k][5]=40;
    }
    else
    {
      tab[k][5]=10;
    }
    tab[k][6]=tab4[i][5][1];

    tab[k][7]=(string)tab4[i][6];
    tab[k][8]="NA";
    tab[k][9]=dpSubStr((string)tab4[i][1],DPSUB_DP_EL);
    k=k+1;
  }
  }

  if(dynlen(tab5)>1)
  {
  for(int i=2;i<=dynlen(tab5);i++)
  {
    tab[k][1]=dpSubStr(tab5[i][1],DPSUB_DP);
    if(tab5[i][3])
    {
      tab[k][2]=1;
    }
    else
    {
      tab[k][2]=2;
    }
    tab[k][3]=UNIXTime(tab5[i][2]);
    tab[k][4]=tab5[i][4][1];
    if(tab5[i][5][1]=="一级报警")
    {
      tab[k][5]=80;
    }
    else if(tab5[i][5][1]=="二级报警")
    {
      tab[k][5]=60;
    }
    else if(tab5[i][5][1]=="三级报警")
    {
      tab[k][5]=40;
    }
    else
    {
      tab[k][5]=10;
    }
    tab[k][6]=tab5[i][5][1];

    tab[k][7]=(string)tab5[i][6];
    tab[k][8]="NA";
    tab[k][9]=dpSubStr((string)tab5[i][1],DPSUB_DP_EL);
    k=k+1;
  }
  }

  int j=1;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if((strpos(tab[i][9],".SUM_ALERT")== -1) && tab[i][5] > 30)
    {
      dt[j++]=tab[i];
    }
  }
  dynClear(tab);
  tab=dt;

  return tab;

}

long UNIXTime(time t)
{
  float f=(float)t*1000;
  long i=(long)f;
  return i;
}

int alarmtype(string type)
{
  if(type=="一级报警")
    return 1;
  else if(type=="二级报警")
    return 2;
  else if(type=="三级报警")
    return 3;
  else return 0;
}
string weberror(int code,string msg)
{
  mapping ret,mPoint;
  dyn_mapping dmPoints;
  mPoint["code"]=code;
  mPoint["msg"]=msg;
  mPoint["data"]=ret;


  string sRet = jsonEncode(mPoint, true);
  //DebugN(ret,sRet);


  return  sRet; // return string.

}

string webRet(mapping con)
{
  mapping ret,mPoint;
  dyn_mapping dmPoints;
  mPoint["code"]=0;
  mPoint["msg"]="请求成功";
  mPoint["data"]=con;

  string sRet = jsonEncode(mPoint, true);
  //DebugN("sRet",sRet);
  return  sRet;
}

















