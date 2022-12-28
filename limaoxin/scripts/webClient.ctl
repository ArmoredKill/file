#uses "CtrlHTTP"

string sversion="1";
string secret_key="b645d880068111ea8f09cf8592eb9fbc";




main()
{

  metadata_updateCB();
  pointdata_updateCB();
  realalarm_update();//realtime/alarm/update



}

void realalarm_update()
{
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  SQL1 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F3*,CUB*,B*}' REMOTE 'DA1:'";
  SQL2 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F3*,CUB*,B*}' REMOTE 'DA2:'";
  SQL3 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F3*,CUB*,B*}' REMOTE 'DA3:'";
  SQL4 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F3*,CUB*,B*}' REMOTE 'DA4:'";
  SQL5 = "SELECT ALERT '_alert_hdl.._direction', '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value' FROM '{F3*,CUB*,B*}' REMOTE 'DA5:'";
  dpQueryConnectSingle("realalarmCB",false, "", SQL1,3000  );
  dpQueryConnectSingle("realalarmCB",false, "", SQL2,3000  );
  dpQueryConnectSingle("realalarmCB",false, "", SQL3,3000  );
  dpQueryConnectSingle("realalarmCB",false, "", SQL4,3000  );
  dpQueryConnectSingle("realalarmCB",false, "", SQL5,3000  );
}

realalarmCB(string s, dyn_dyn_anytype dtab)
{
  //DebugTN("报警推送开始");
  dyn_dyn_anytype tab;
  tab=realtime_alarmCB(dtab);
//DebugTN("数据分组",tab);
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  string uuid;
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

  mapping result;
  string ssign;
  int sta;
  long t;
  t=TimeNow();


  ssign=cryptoHash(sversion + (string)t + secret_key);


  netPost("http://10.251.56.11:8002/realtime/alarm/update",//http://10.251.56.11:8002/realtime/alarm/update
            makeMapping("content", jsonEncode(ret),
                        "headers", makeMapping("Content-Type", "application/json;charset=utf-8" ,  // text/html??  application/json??
                                               "version", sversion,
                                               "timestamp", t,
                                               "sign", ssign)

                        ),
            result
            );


DebugTN("报警推送完成",dynlen(dmPoints),result);
}
}


void pointdata_updateCB()
{
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  SQL1 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA1:'";
  SQL2 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA2:'";
  SQL3 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA3:'";
  SQL4 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA4:'";
  SQL5 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA5:'";
  dpQueryConnectSingle("pudataCB",false, "", SQL1,30000  );
  dpQueryConnectSingle("pudataCB",false, "", SQL2,30000  );
  dpQueryConnectSingle("pudataCB",false, "", SQL3,30000  );
  dpQueryConnectSingle("pudataCB",false, "", SQL4,30000  );
  dpQueryConnectSingle("pudataCB",false, "", SQL5,30000  );
}

pudataCB(string s, dyn_dyn_anytype dtab)
{
  //DebugTN("动态数据推送开始");
  dyn_dyn_anytype tab;
  tab=Online_mergeCB(dtab);
//DebugTN("数据分组",tab);
  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int z=1;
  mapping result;
  string ssign;
  int sta;
  long t;
  mapping ret;


  if(dynlen(tab)>0)
  {
    //DebugN("dpe数量",dynlen(tab));
    for(int i=1;i<=dynlen(tab);i++)
  {
        uniStrReplace(tab[i][2],tab[i][1]+".","");
        mPoint["point_id"]=tab[i][1];
        mPoint["name"]=tab[i][2];
        mPoint["value"]=tab[i][3];
        mPoint["unit"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["timestamp"]=(string)UNIXTime(tab[i][6]);

        dynAppend(dmPoints, mPoint);

        if(z==5000)
        {
          ret["points"] = dmPoints;
          t=TimeNow();
          ssign=cryptoHash(sversion + (string)t + secret_key);
        netPost("http://10.251.56.11:8002/realtime/point/update",
            makeMapping("content", jsonEncode(ret),
                        "headers", makeMapping("Content-Type", "application/json;charset=utf-8" ,  // text/html??  application/json??
                                               "version", sversion,
                                               "timestamp", t,
                                               "sign", ssign)

                        ),
            result
            );
        DebugTN("5000",dynlen(dmPoints),"动态数据推送完成",result);
        z=1;
        dynClear(dmPoints);
          delay(1);
        }
        z=z+1;

  }

  //DebugTN("分组完成");



  ret["points"] = dmPoints;


  t=TimeNow();


  ssign=cryptoHash(sversion + (string)t + secret_key);


  sta=netPost("http://10.251.56.11:8002/realtime/point/update",
            makeMapping("content", jsonEncode(ret),
                        "headers", makeMapping("Content-Type", "application/json;charset=utf-8" ,  // text/html??  application/json??
                                               "version", sversion,
                                               "timestamp", t,
                                               "sign", ssign)

                        ),
            result
            );

    DebugTN(dynlen(tab),dynlen(dmPoints),"动态数据推送完成",result);
  }
}

void metadata_updateCB()
{
  string SQL1,SQL2,SQL3,SQL4,SQL5;
  SQL1 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA1:'";
  SQL2 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA2:'";
  SQL3 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA3:'";
  SQL4 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA4:'";
  SQL5 = "SELECT '_online.._value', '_online.._stime' FROM '{F3*,CUB*,B*}' REMOTE 'DA5:'";
  dpQueryConnectSingle("mudataCB",false, "", SQL1,30000  );
  dpQueryConnectSingle("mudataCB",false, "", SQL2,30000  );
  dpQueryConnectSingle("mudataCB",false, "", SQL3,30000  );
  dpQueryConnectSingle("mudataCB",false, "", SQL4,30000  );
  dpQueryConnectSingle("mudataCB",false, "", SQL5,30000  );
}

mudataCB(string s, dyn_dyn_anytype dtab)
{
  dynDynSort(dtab,1);
  //DebugN("*********************************************");
  //DebugTN("开始",dtab);
  dyn_dyn_anytype dts,tab,dp,ct,st,aa;
  mapping mPoint;
  dyn_mapping points;
  int x=2,k=1,y,datp,zz=1;
  string dpn,dsys;
  string sql;
  dyn_string ds;
  st[1]=dtab[1];
  for(int i=2;i<=dynlen(dtab);i++)
  {
    datp=DataType(dtab[i][1],dpTypeName(dtab[i][1]));
    if(datp==1 || datp==3)
    {
    if(x>2)
    {
      y=dynContains(aa[1],dpSubStr(dtab[i][1],DPSUB_DP));
      if((!(y!=0 && aa[2][y]==datp)))
    {
      st[x++]=dtab[i];
    }
    }
    else
    {
      st[x++]=dtab[i];
    }
    aa[1][zz]=dpSubStr(dtab[i][1],DPSUB_DP);
    aa[2][zz++]=datp;
  }
  }
  dynClear(dtab);
  dtab=st;
  //DebugTN("过滤重复",dtab);
  //DebugTN("过滤重复",dynlen(dtab));
  dyn_dyn_anytype dSQL1,dSQL2;
  int d1=1,d2=1;

  for (int i = 2; i <= dynlen(dtab); i++)
  {
  //dtab[i][1]=dpSubStr((string)dtab[i][1],DPSUB_DP_EL)
    x=DataType(dtab[i][1],dpTypeName(dtab[i][1]));

    dpn=dpSubStr(dtab[i][1],DPSUB_SYS_DP);
    dsys=dpSubStr(dtab[i][1],DPSUB_SYS);
    if(x==1)
    {
    dSQL1[d1][1]=dpn;
    dSQL1[d1++][2]=dsys;
  }
    else if(x==3)
    {
    dSQL2[d2][1]=dpn;
    dSQL2[d2++][2]=dsys;
  }
  }
  /*dynDynSort(dSQL1,2);
  dynDynSort(dSQL2,2);*/
  //DebugTN("dSQL",dynlen(dSQL1),dynlen(dSQL2),dSQL1[1][1]);
  string SSQL;
  if(dynlen(dSQL1)>0)
  {
  for (int i = 1; i <= dynlen(dSQL1); i++)
  {
    if(i==1)
    {
      SSQL=dSQL1[i][1];
    }
    else
    {
      SSQL = SSQL+","+dSQL1[i][1];
    }
  }
    //DebugTN("SSQL",SSQL);
  sql ="SELECT '_online.._value', '_online.._stime' FROM '{ ";
      sql+= SSQL + " }' REMOTE ";//'DA1:'
      sql+= "'"+dSQL1[1][2]+"'";
      //DebugN("sql",sql);
      dynClear(ct);
      dpQuery(sql,ct);
      //DebugTN("SSQL",dynlen(ct),ct);
      for(int i=2;i<=dynlen(ct);i++)
      {
        if((DataType(ct[i][1],dpTypeName(ct[i][1]))==1)  )
        {
          dts[k++]=ct[i];
        }
      }
    }

  if(dynlen(dSQL2)>0)
  {
  for(int i=1;i<=dynlen(dSQL2);i++)
  {
    if(i==1)
    {
      SSQL=dSQL2[i][1];
    }
    else
    {
      SSQL = SSQL+","+dSQL2[i][1];
    }
  }
      sql ="SELECT '_offline.._value', '_offline.._stime' FROM '{ ";
      sql+= SSQL + " }' REMOTE ";//'DA1:'
      sql+= "'"+dSQL2[1][2]+"'";
      dpQuery(sql,ct);
      delay(0,10);
      for(int i=2;i<=dynlen(ct);i++)
      {
        if((DataType(ct[i][1],dpTypeName(ct[i][1]))==3) )//&& dynContains(at[1],ct[i][1])>0
        {
          dts[k++]=ct[i];
        }
      }
    }



  dynDynSort(dts,1);

  tab=mergeCB(dts);

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
  //DebugTN("dp");

  mapping mPoint,mDP;
  dyn_mapping points;
  dyn_mapping dmPoints;
  string kk;
  int pl,z;
  int kp=1;
  z=1;
  mapping result;
  string ssign;
  int sta;
  long t;
  mapping ret;


if(dynlen(tab)>0)
  {
    //DebugN("dpe数量",dynlen(tab));
    //DebugN("dp数量",dynlen(dp));
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
        mPoint["timestamp"]=(string)UNIXTime(tab[i][7]);

        dynAppend(dmPoints, mPoint);
      }
  else
  {
    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);

    if(dynlen(points)==20)
        {
          ret["points"] = points;
          t=TimeNow();
          ssign=cryptoHash(sversion + (string)t + secret_key);
        netPost("http://10.251.56.11:8002/metadata/update",//"http://10.251.56.11:8002/metadata/update"
            makeMapping("content", jsonEncode(ret),
                        "headers", makeMapping("Content-Type", "application/json;charset=utf-8" ,  // text/html??  application/json??
                                               "version", sversion,
                                               "timestamp", t,
                                               "sign", ssign)

                        ),
            result
            );
        DebugTN("20",dynlen(points),dynlen(tab),"基础数据推送完成",result);
        if(strpos(result["content"],"Send failed")>0)
          {
            DebugN("result",points);
          }
        kp=1;
        dynClear(points);
          delay(1);
        }

    uniStrReplace(tab[i][1],dp[z]+".","");
        mPoint["name"]=tab[i][1];
        mPoint["desc"]=tab[i][2];
        mPoint["category"]=tab[i][3];
        mPoint["value"]=tab[i][4];
        mPoint["type"]=tab[i][5];
        mPoint["unit"]=tab[i][6];
        mPoint["timestamp"]=(string)UNIXTime(tab[i][7]);

    dynAppend(dmPoints, mPoint);
    mDP["point_id"]=tab[i][8];
    mDP["dp_type"]=tab[i][9];
    z=z+1;

  }



  }
    mDP["attribute"]=dmPoints;

    dynClear(dmPoints);
    dynAppend(points, mDP);

//DebugTN("格式化完成");

  ret["points"] = points;



  t=TimeNow();


  ssign=cryptoHash(sversion + (string)t + secret_key);

  netPost("http://10.251.56.11:8002/metadata/update",//"http://10.251.56.11:8002/metadata/update"
            makeMapping("content", jsonEncode(ret),
                        "headers", makeMapping("Content-Type", "application/json;charset=utf-8" ,  // text/html??  application/json??
                                               "version", sversion,
                                               "timestamp", t,
                                               "sign", ssign)

                        ),
            result
            );

DebugTN("基础数据推送完成*****************************",dynlen(points),dynlen(tab),result);
}

}



string format(string dpe,anytype value)
{
  string a;
  langString form;
  form=dpGetFormat(dpe);
  //DebugN(value,form);
  if(form[1]=="" || value==FALSE ||  value==TRUE)
  {
    return (string)value;
  }
  else
  {
    sprintf(a,form[1],value);
    uniStrReplace(a," ","");
    return a;
  }
}

dyn_dyn_anytype mergeCB(dyn_dyn_anytype tab1, dyn_dyn_anytype tab2="", dyn_dyn_anytype tab3="", dyn_dyn_anytype tab4="", dyn_dyn_anytype tab5="")
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
    tab[k][5]=data_type((string)tab1[i][1]);
    tab[k][6]=dpGetUnit(tab1[i][1])[1];
    tab[k][7]=(string)tab1[i][3];
    tab[k][8]=dpSubStr(tab1[i][1],DPSUB_DP);
    tab[k][9]=dpTypeName(tab1[i][1]);
    tab[k][3]=DataType(tab1[i][1],tab[k][9]);

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

string msys(string dp)
{
  if(strpos(dp,"_CR_")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_PEX_")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_PCW_")>0 || strpos(dp,"_PV_")>0 || strpos(dp,"_HV_")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_VOC _")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_NMHC_")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_UPW_")>0)
    {
      return "'DA1:'";
    }
    else if(strpos(dp,"_CDS_")>0)
    {
      return "'DA2:'";
    }
    else if(strpos(dp,"_GMS_")>0)
    {
      return "'DA2:'";
    }
    else if(strpos(dp,"_SDS_")>0)
    {
      return "'DA2:'";
    }
    else if(strpos(dp,"_PLB_")>0)
    {
      return "'DA3:'";
    }
    else if(strpos(dp,"_GHVAC_")>0)
    {
      return "'DA3:'";
    }
    else if(strpos(dp,"_CUS_")>0)
    {
      return "'DA3:'";
    }
    else if(strpos(dp,"_AMT_")>0)
    {
      return "'DA4:'";
    }
  else if(strpos(dp,"_LK_")>0)
    {
      return "'DA4:'";
    }
  else if(strpos(dp,"_PSO_")>0)
    {
      return "'DA4:'";
    }
    else if(strpos(dp,"_PMS_")>0)
    {
      return "'DA5:'";
    }
    else if(strpos(dp,"_FMCS_")>0)
    {
      return "'DA5:'";
    }
    else if(strpos(dp,"_WWT_")>0)
    {
      return "'DA5:'";
    }
  else
    {
      return "'DA1:'";
    }
}


//合并表格、提取6个元素、去除多余DPE，动态数据
dyn_dyn_anytype Online_mergeCB(dyn_dyn_anytype tab1)
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

long TimeNow()
{
  time t;
  t=getCurrentTime();
  float f=(float)t*1000;
  long i=(long)f;
  return i;
}

//合并表格、提取6个元素、去除多余DPE，动态数据
dyn_dyn_anytype realtime_alarmCB(dyn_dyn_anytype tab1)
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




  //删除MINUTE、HOUR值和SUM_ALERT、NOTE,以及只要动态数据;
  //if(strpos(sDpe, ".SUM_ALERT")>=0) continue;
  int j=1;
  for(int i=1;i<=dynlen(tab);i++)
  {
    if((strpos(tab[i][9],".SUM_ALERT")== -1) )
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
