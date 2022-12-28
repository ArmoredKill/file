#uses "as"
#uses "CtrlHTTP"
#uses "webServerlib"
#uses "FMCSLibs/SPC"

mapping mSubSystem = makeMapping("PEX","'DA1:'",
                                 "CR","'DA1:'",
                                 "PCW","'DA4:'",//DA1
                                 "VOC","'DA1:'",
                                 "NMHC","'DA1:'",
                                 "UPW","'DA1:'",
                                 "CDS","'DA2:'",
                                 "GMS","'DA2:'",
                                 "SDS","'DA2:'",
                                 "PLB","'DA3:'",
                                 "GHVAC","'DA3:'",
                                 "CUS","'DA3:'",
                                 "AMT","'DA4:'",
                                 "LK","'DA4:'",
                                 "PSO","'DA4:'",
                                 "ILINE","'DA4:'",
                                 "PMS","'DA5:'",
                                 "WWT","'DA5:'",
                                 "FMCS","'DA5:'");

mapping mpath     =   makeMapping("PEX","ME",
                                 "CR","ME",
                                 "PCW","ME",//DA1
                                 "VOC","ME",
                                 "NMHC","ME",
                                 "UPW","Water",
                                 "CDS","GC",
                                 "GMS","GC",
                                 "SDS","GC",
                                 "PLB","Water",
                                 "GHVAC","ME",
                                 "CUS","ME",
                                 "AMT","Water",
                                 "LK","Water",
                                 "PSO","EE",
                                 "ILINE","EE",
                                 "PMS","EE",
                                 "WWT","Water",
                                 "FMCS","GC",
                                 "ME","ME",
                                 "GC","GC",
                                 "Water","Water",
                                 "EE","EE");

mapping mFROM = makeMapping(
                                 "PEX","'{CUB*_PEX_*,F3P1*_PEX_*,B*_PEX_*}' ",
                                 "CR","'{CUB*_CR_*,F3P1*_CR_*,B*_CR_*}' ",
                                 "PCW","'{CUB*_PCW_*,F3P1*_PCW_*,B*_PCW_*,CUB*_PV_*,F3P1*_PV_*,B*_PV_*,CUB*_HV_*,F3P1*_HV_*,B*_HV_*}' ",
                                 "VOC","'{CUB*_VOC_*,F3P1*_VOC_*,B*_VOC_*}' ",
                                 "NMHC","'{CUB*_NMHC_*,F3P1*_NMHC_*,B*_NMHC_*}' ",
                                 "UPW","'{CUB*_UPW_*,F3P1*_UPW_*,B*_UPW_*}' ",
                                 "CDS","'{CUB*_CDS_*,F3P1*_CDS_*,B*_CDS_*}' ",
                                 "GMS","'{CUB*_GMS_*,F3P1*_GMS_*,B*_GMS_*}' ",
                                 "SDS","'{CUB*_SDS_*,F3P1*_SDS_*,B*_SDS_*}' ",
                                 "PLB","'{CUB*_PLB_*,F3P1*_PLB_*,B*_PLB_*}' ",
                                 "CUS","'{CUB*_CUS_*,F3P1*_CUS_*,DG1*_CUS_*,B*_CUS_*}' ",
                                 "GHVAC","'{CUB*_GHVAC_*,F3P1*_GHVAC_*,B*_GHVAC_*}' ",
                                 "AMT","'{CUB*_AMT_*,F3P1*_AMT_*,B*_AMT_*}' ",
                                 "LK","'{CUB*_LK_*,F3P1*_LK_*,B*_LK_*}' ",
                                 "PSO","'{CUB*_PSO_*,F3P1*_PSO_*,B*_PSO_*}' ",
                                 "ILINE","'{CUB*_ILINE_*,F3P1*_ILINE_*,B*_ILINE_*}' ",
                                 "PMS","'{CUB*_PMS_*,F3P1*_PMS_*,B*_PMS_*}' ",
                                 "WWT","'{CUB*_WWT_*,F3P1*_WWT_*,B*_WWT_*}' ",
                                 "FMCS","'{CUB*_FMCS_*,F3P1*_FMCS_*}' ");
mapping mColor;
bool debugFlag=1;

mapping mAlertType = makeMapping(1,"实时",
                                 2,"历史");

mapping mAlertState = makeMapping(0,"全部",
                                  1,"未确认报警",
                                  2,"新增报警",
                                  3,"未确认与新增报警");
main()
{
  iniColor();
  httpServer(0,80,0);
  httpSetMaxContentLength( 1024 * 1024 * 1024 * 1);
  httpConnect("FMCSAlertsCB", "/FMCSAlertQuery", "text/html charset=utf8");
  timedFunc("DailyReport","CORE:_daily");
  timedFunc("WeeklyReport","CORE:_weekly");
  SPC_WebReporting();

  httpConnect("LK_WEBCB", "/LK_WEB","application/json charset=UTF-8");

  httpConnect("metadataCB", "/metadata/query","application/json"); // app:  /firstExample   application/json
   httpConnect("OnlineDataCB", "/realtime/point/query","application/json");
   httpConnect("HistoryDataCB", "/history/point/query","application/json");
   httpConnect("RealAlarmCB", "/realtime/alarm/query","application/json");
   httpConnect("HistoryAlarmCB", "/history/alarm/query","application/json");

   httpConnect("OnlineupCB", "/realtime/point/update","application/json charset=UTF-8");
   httpConnect("AlarmupCB", "/realtime/alarm/update","application/json charset=UTF-8");

}

void LK_WEBCB( blob content  , string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  mapping m;
  string str,sRet;
  //DebugTN("LK数据同步开始");
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
   dyn_mapping s = m["points"];
   dyn_string dpe;
   dyn_anytype value;
   int x=1;
   int y=1;
   string name;
   for(int i=1;i<=dynlen(s);i++)
   {
     uniStrReplace(s[i]["name"],"System1:","DA4:");
     dpe[x++]=s[i]["name"];
     value[y++]=s[i]["value"];
   }
   int sta=dpSet(dpe,value);
   DebugTN("LK数据同步",sta,dynlen(s));
   //DebugN(s);


}
void AlarmupCB( blob content  , string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  mapping m;
  string str,sRet;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
   DebugN("content", content,
          "headerNames",headerNames,
          "headerValues",headerValues) ;


}
void OnlineupCB( blob content  , string user  , string ip  , dyn_string headerNames  , dyn_string headerValues  , int connectionIndex )
{
  mapping m;
  string str,sRet;
  if (bloblen(content) > 0)
  {
    blobGetValue(content, 0, str, bloblen(content));
    m = jsonDecode(str);
  }
   DebugN("动态数据content",dynlen(m["points"]),m["points"]) ;


}

DailyReport(string Daily,time t1, time t2)
{
  uint interval;
  dpGet("CORE:_daily.interval",interval);
  //t2="2022.08.30 08:00:00.000";
  t1=t2-interval;
  DebugN(t1,t2);
  string sUser;
  string st1,st2;
  st1=t1;
  st2=t2;
  dyn_string asValue;
  dyn_string sys = makeDynString(
      "EE","Water","GC","ME"//,"CR","PEX","PCW","VOC","NMHC","UPW","CDS","SDS","GMS","PLB","CUS","GHVAC","AMT","LK","PSO","ILINE","PMS","WWT"
      );
  dyn_string asParameter= makeDynString("subsystem", "timeRange",
                                        "t1","t2",
                                        "alertState","filter");
  for(int i=1;i<=dynlen(sys);i++)
  {
    asValue=makeDynString(sys[i],"2",
                          st1,st2,
                          "0","*");
    FMCSAlertReport(asParameter,asValue,"","DailyReport");
    delay(0,100);
  }

  //statistics(st1,st2);

}


WeeklyReport(string Weekly,time t1, time t2)
{
  uint interval;
  dpGet("CORE:_weekly.interval",interval);
  //t2="2022.08.30 08:00:00.000";
  t1=t2-interval;
  DebugN(t1,t2);
  string sUser;
  string st1,st2;
  st1=t1;
  st2=t2;
  dyn_string asValue;
  dyn_string sys = makeDynString(
      "EE","Water","GC","ME"//"CR","PEX","PCW","CDS","SDS","FMCS","VOC","CUS","GHVAC"
      );
  dyn_string asParameter= makeDynString("subsystem", "timeRange",
                                        "t1","t2",
                                        "alertState","filter");
  for(int i=1;i<=dynlen(sys);i++)
  {
    asValue=makeDynString(sys[i],"2",
                          st1,st2,
                          "0","*");
    FMCSAlertReport(asParameter,asValue,"","WeeklyReport");
    delay(0,100);
  }
}
/*
WCCOActrl2:[dyn_string 17 items
WCCOActrl2:     1: "timeRange"
WCCOActrl2:     2: "t1Day"
WCCOActrl2:     3: "t1Month"
WCCOActrl2:     4: "t1Year"
WCCOActrl2:     5: "t1Hour"
WCCOActrl2:     6: "t1Minute"
WCCOActrl2:     7: "t1Second"
WCCOActrl2:     8: "t2Day"
WCCOActrl2:     9: "t2Month"
WCCOActrl2:    10: "t2Year"
WCCOActrl2:    11: "t2Hour"
WCCOActrl2:    12: "t2Minute"
WCCOActrl2:    13: "t2Second"
WCCOActrl2:    14: "alertState"
WCCOActrl2:    15: "filter"
WCCOActrl2:    16: "get"
WCCOActrl2:    17: "maxLines"
WCCOActrl2:][dyn_string 17 items
WCCOActrl2:     1: "1"
WCCOActrl2:     2: "15"
WCCOActrl2:     3: "05"
WCCOActrl2:     4: "2022"
WCCOActrl2:     5: "00"
WCCOActrl2:     6: "00"
WCCOActrl2:     7: "00"
WCCOActrl2:     8: "16"
WCCOActrl2:     9: "05"
WCCOActrl2:    10: "2022"
WCCOActrl2:    11: "23"
WCCOActrl2:    12: "59"
WCCOActrl2:    13: "59"
WCCOActrl2:    14: "0"
WCCOActrl2:    15: "*"
WCCOActrl2:    16: "查询报警"
WCCOActrl2:    17: "20"
*/

string FMCSAlertsCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
  /*DebugN("asParameter",asParameter);
  DebugN("asValue",asValue);
  DebugN("sUser",sUser);
  DebugN("sIP",sIP);*/
  DebugTN("Alarm报表查询开始",asValue[1]);
int     i,j, iErr, iPos;
time    t1, t2;         // Start and end-time
string  sT1, sT2,TX01;       // Start and end-time
string  sFilter;        // DP-Filter
string  sAction;        // Action (get-table/load-props/save-props)
int     iMaxLines;      // Maximum tablelines for each page
string  query;          // Querystring
string  from, where;    // Query-states FROM/WHERE
string  html; // HTML answer
string  sFile;          // Filename for properties
dyn_dyn_anytype tab, sortedtab,stab,tab1,tab2,tab3,tab4,tab5;   // Query-Result
dyn_dyn_string  rettab;           // Table-Lines
dyn_string  valDpList;            // DP-Filter-Liste
int         valType;              // At this Moment=1 / Closed=2
int         valState;             // Alert-State
string      valPrio= "40-100";    // Alert-Priority
bool        valTypeAlertSummary= true;
string      valShortcut;
string      valAlertText;
dyn_int     valTypeSelections;
int         row, col, pos;
string subsystem;

//DebugN("***Aufruf von alertCB***",sIP);
for(i=1; i<=dynlen(asParameter); i++)
  // DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  iPos= dynContains(asParameter, "subsystem");
  if(iPos>0) subsystem= asValue[iPos];

  t1= getTimeFromParameter("t1", asParameter, asValue);
  t2= getTimeFromParameter("t2", asParameter, asValue);
  //DebugN("时间1******",t1,t2);
  sT1= t1;
  sT2= t2;
  //DebugN("时间1******",sT1,sT2);
  iPos= dynContains(asParameter, "filter");
  if(iPos>0) sFilter= asValue[iPos];
  strreplace(sFilter, "\r", "");
  valDpList = strsplit(sFilter, "\n");
  iPos= dynContains(asParameter, "alertState");
  if(iPos>0)  valState= asValue[iPos];
  iPos= dynContains(asParameter, "timeRange");
  if(iPos>0)  valType= asValue[iPos];

  as_getFromWhere(from, where,
                  valState, valShortcut, valPrio, valAlertText,
                  valDpList, valTypeSelections, valTypeAlertSummary, valType);

  if(subsystem=="ME")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_PEX_*,F*_PEX_*,B*_PEX_*,"
           "CUB*_CR_*,F*_CR_*,B*_CR_*,"
           "CUB*_PCW_*,F*_PCW_*,B*_PCW_*,CUB*_PV_*,F*_PV_*,B*_PV_*,CUB*_HV_*,F*_HV_*,B*_HV_*,"
           "CUB*_VOC_*,F*_VOC_*,B*_VOC_*,"
           "CUB*_NMHC_*,F*_NMHC_*,B*_NMHC_*"
         "}' ";//from;
  query += " REMOTE 'DA1:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_CUS_*,F*_CUS_*,B*_CUS_*,"
           "CUB*_GHVAC_*,F*_GHVAC_*,B*_GHVAC_*"
         "}' ";//from;
  query += " REMOTE 'DA3:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA3:'");

  dynRemove(tab2,1);
  dynAppend(tab1,tab2);
  rettab=tab1;

  }

  else if(subsystem=="GC")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*,F*,B**}' ";//from;
  query += " REMOTE 'DA2:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  rettab = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");

  }


  else if(subsystem=="Water")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_UPW_*,F*_UPW_*,B*_UPW_*}' ";//from;
  query += " REMOTE 'DA1:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_AMT_*,F*_AMT_*,B*_AMT_*,"
           "CUB*_LK_*,F*_LK_*,B*_LK_*"
         "}' ";//from;
  query += " REMOTE 'DA4:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA4:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);





  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_WWT_*,F*_WWT_*,B*_WWT_*}' ";//from;
  query += " REMOTE 'DA5:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab3 = FMCS_ConvertAlertTab( sortedtab ,"'DA5:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);



  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PLB_*,F*_PLB_*,B*_PLB_*}' ";//from;
  query += " REMOTE 'DA3:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab4 = FMCS_ConvertAlertTab( sortedtab ,"'DA3:'");




  dynRemove(tab2,1);
  dynRemove(tab3,1);
  dynRemove(tab4,1);
  dynAppend(tab1,tab2);
  dynAppend(tab1,tab3);
  dynAppend(tab1,tab4);
  rettab=tab1;

  }

  else if(subsystem=="EE")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PSO_*,F*_PSO_*,B*_PSO_*,"
           "CUB*_ILINE_*,F*_ILINE_*,B*_ILINE_*}' ";//from;
  query += " REMOTE 'DA4:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA4:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PMS_*,F*_PMS_*,B*_PMS_*}' ";//from;
  query += " REMOTE 'DA5:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  dpQuery(query,stab);
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA5:'");


  dynRemove(tab2,1);
  dynAppend(tab1,tab2);
  rettab=tab1;

  }



  else
  {

  //DebugN("from:",from);
 // TX01 = " AND "+mSQL[subsystem];
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM "+mFROM[subsystem];//from;
  query += " REMOTE "+ mSubSystem[subsystem];
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";


  dpQuery(query,stab);

  //DebugN("Query:",query);

    uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  rettab = FMCS_ConvertAlertTab( sortedtab ,mSubSystem[subsystem]);
  //DebugN("<<<rettab>>>");
}
  //DebugN(rettab[1]);
  dynDynSort(rettab,2);
  DebugTN("Alarm报表查询结束",dynlen(rettab));
  html =
"<html>"
"<head>"
"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
"<link rel=\"stylesheet\" href=\"/data/alarmreport/style.css\">"
"<title>FMCS报警报表</title>"
"</head>"
"<body align=center>"
"<style>"
"button {"
            "height: 30px;"
            "width: 100px;"
            "margin: 20px 20px;"
            "background: yellowgreen;"
            "border-radius: 10px;"
            "outline: none;"
        "}"
"</style>"
;

 html +=

"</tr>"
"<button id=\"out\" onclick=\"btn_export()\">打印报表</button>"
"</tr>"

"</p>"
;
 html +=
"<table id=\"tb\">"

"<tr bgcolor=\"#00BFFF\">"
"<th>子系统</th>"
"<th>起始时间</th>"
"<th>结束时间</th>"
"<th>筛选条件</th>"
"<th>报警类型</th>"
"<th>报警状态</th>"
"</tr >"
"<tr valign=\"center\" align=\"center\">"
//"<font color=\"#FF0000\">""</font>"
"<td>" + subsystem + "</td>"
"<td>" + sT1 + "</td>"
"<td>" + sT2 + "</td>"
"<td>" + sFilter + "</td>"
"<td>"+mAlertType[valType]+"</td>"
"<td>"+mAlertState[valState]+"</td>"
"</tr>"


"<tr bgcolor=\"#00BFFF\">"
"<th>DP变量名</th>"
"<th>时间</th>"
"<th>等级</th>"
//"<th>等级数字</th>"
"<th>报警描述</th>"
"<th>报警值</th>"
"<th>报警类型</th>"
"<th>设定值</th>"
"<th>报警方向</th>"
"<th>确认者</th>"
"<th>确认状态</th>"
"</tr>"
;


  for (int i = 1; i <= dynlen(rettab); i++)
  {
    // DebugN("<<<rettab>>>",rettab[i] );

    // PEX:F3P1A_4F_PEX_GEX01_ZT.ERROR.H_ALM.VALUE	2022.05.05 11:58:12.138	Alert Level 2	60	05/05/22 11:58:12.138	阀门开度反馈.高报警	F3P1A_4F_PEX_GEX01_ZT 高报警	CAME	BOOL	已确认(xxx)	yellow
    string color = rettab[i][dynlen(rettab[i])];
    html+="<tr bgcolor="+color+">";

    int j;


      for (j = 1; j <  dynlen(rettab[i]); j++)
      {
        if(j!=4) html+="<td>"  +  rettab[i][j] + "</td>";

      }


    html+="</tr>";


  }

html += "</table>"
"<script src=\"/data/alarmreport/xlsx.core.min.js\"></script>"
"<script src=\"/data/alarmreport/jquery.min.js\"></script>"
"<script src=\"/data/alarmreport/excel.js\"></script>"
"<script>"
        "function btn_export() {"
            "var table = document.querySelector(\"#tb\");"
            "var sheet = XLSX.utils.table_to_sheet(table);" //将一个table对象转换成一个sheet对象
            "openDownloadDialog(sheet2blob(sheet), '"+subsystem+"-AlarmChart.xlsx');"
        "}</script>"
"</body></html>";



  return(html);
}

time getTimeFromParameter(string sTime, dyn_string &asParameter, dyn_string &asValue)
{
int i;
dyn_int aiTime;
dyn_string asTimePara= makeDynString("Year", "Month", "Day",
                                     "Hour", "Minute", "Second");
int iYear, iMonth, iDay;
int iHour, iMinute, iSecond, iMsec;
int iPos, iTime;

  aiTime[7]= 0;
  for(i=dynlen(asTimePara); i>0; i--)
  {
    iPos= dynContains(asParameter, sTime+asTimePara[i]);
    if(iPos>0)
    {
      aiTime[i]= asValue[iPos];
      dynRemove(asParameter, iPos);
      dynRemove(asValue, iPos);
    }
  }
  // Complet time given
  if(aiTime[1]>0)
    return( makeTime(aiTime[1],aiTime[2],aiTime[3],
                     aiTime[4],aiTime[5],aiTime[6]) );
  // time-interval given
  else
    return( aiTime[3]*86400 + aiTime[4]*3600 +
            aiTime[5]*60 + aiTime[6] );
}

//=============================================================================
// Convert the Alert-query-result table
//=============================================================================

// Changes: [Date]-[Name]:[Changes]
//=============================================================================
dyn_dyn_anytype FMCS_ConvertAlertTab(dyn_dyn_anytype &tab,string sys)
{
int i;
dyn_dyn_string ret;
string         sDpe, sDpeLang, sText;
string         sDir, sAck, sAckStr,stm;
time           t;
int            iPrio,num;
int j = 1;

  for(i=2; i<=dynlen(tab); i++)
  {
    t= tab[i][2];
    iPrio= tab[i][4];
    sDpe= tab[i][1];

    if(strpos(sDpe, ":_")>=0) continue; // 忽略内部Dp
    if(strpos(sDpe, ".SUM_ALERT")>=0) continue; // 忽略 SUM ALERT


    if(sDpeLang=="")
      sDpeLang= dpSubStr(sDpe, DPSUB_DP_EL);


    if(tab[i][8]==DPATTR_ACKTYPE_SINGLE)          sAck= "已确认(x)";
    else if(tab[i][8] == DPATTR_ACKTYPE_MULTIPLE) sAck= "已确认(xxx)";
    else
    {
      if(tab[i][11])  // _ackable
        sAck= tab[i][13] ? "未确认(!!!)":"未确认(!)";  // oldest Ack
      else
        sAck= tab[i][12] ? "无需确认":"/";  // _ack_oblig
    }
    if(strpos(sAck,"x")==0)       sAckStr= getCatStr("http", "ack",   getLangId( "zh_CN.utf8" )  );
    else if(strpos(sAck,"!")==0)  sAckStr= getCatStr("http", "unack", getLangId( "zh_CN.utf8" )  );
    else                          sAckStr= sAck;

    string sDp= dpSubStr(tab[i][1], DPSUB_SYS_DP);
    //DebugN(sDp);
    string tepy,sta="";
    string SSP1,SSP2;
    float SPv1,SPv2;
    string  SQLQ;
    time ti1,ti2;
    dyn_dyn_anytype stab;

    dyn_string ds1,ds2;


    if(strpos(sDpe, ".HH.")>=0) sta="HH";
    else if(strpos(sDpe, ".H.")>=0) sta="H";
    else if(strpos(sDpe, ".L.")>=0) sta="L";
    else if(strpos(sDpe, ".LL.")>=0) sta="LL";
    else if(strpos(sDpe, ".HH_")>=0) sta="HH";
    else if(strpos(sDpe, ".H_")>=0) sta="H";
    else if(strpos(sDpe, ".L_")>=0) sta="L";
    else if(strpos(sDpe, ".LL_")>=0) sta="LL";
    else if(strpos(sDpe, ".SEGMENT.")>=0)//strpos(sDpe, ".HH.")>=0 || strpos(sDpe, ".H.")>=0 || strpos(sDpe, ".L.")>=0 || strpos(sDpe, ".LL.")>=0 ||
    {
      dyn_string ds1 = strsplit(sDpe,".");
      num=dynContains(ds1,"SEGMENT");
      sta = ds1[num+1];
    }

    if(sta!="" && sta!="AI" && sta!="ALL")
    {
    string ssDpe1=sDp +".SEGMENT."+sta+".SP.VALUE";
    string ssDpe2=sDp +".STATE.VAL_IN.VALUE";

    ti1=tab[i][2];
    ti2=ti1+30;


    if(!dpExists(ssDpe1))
    {
      DebugN(ssDpe1,"ssDpe1不存在·");
      SSP1="NA";
      SSP2="NA";
      sta="";
    }
    else
    {
    dpGet(ssDpe1,SPv1);
    format(ssDpe1,SPv1);
    SSP1=format(ssDpe2,SPv1);
    //}
    /*if(!dpExists(ssDpe2))
    {
    DebugN(ssDpe2,"ssDpe2不存在·");
      SSP2="NA";
    }
    else
    {*/

      SQLQ = "SELECT ALL '_online.._value'";
      SQLQ +=" FROM '"+ ssDpe2 + "'";
      SQLQ +=" REMOTE "+sys;
      SQLQ +=" TIMERANGE(\""+(string)ti1+"\",\""+(string)ti2+"\",1,0)";
      //DebugN("测试*********1",SQLQ);
      dpQuery(SQLQ,stab);
      //DebugN("测试*********2",stab);
      if(dynlen(stab)<2)
      {
        SSP2="NA";
      }
      else
      {
        SPv2=stab[2][2];//format(ssDpe2,stab[2][2]);
        SSP2=(string)SPv2;
      }

    }
  }
    else
    {
    sta="DES";
    SSP1="NA";
    SSP2="NA";
  }
    if(sta == "") tepy="DES";
    else if(sta=="HH") tepy="HiHi";
    else if(sta=="H") tepy="Hi";
    else if(sta=="L") tepy="Lo";
    else if(sta=="LL") tepy="LoLo";
    else if(sta=="DES") tepy="DES";
    else tepy=sta+"段报警";






    //DebugN(tab[i]);
    /*
WCCOActrl2:	     1: "DA1:F3P1A_3F_CR_DCC_P5.ERROR.ALL_ALARM.VALUE"
WCCOActrl2:	     2: "2022.07.18 16:17:56.616"
WCCOActrl2:	     3: "二级报警"
WCCOActrl2:	     4: "60"
WCCOActrl2:	     5: "F3P1A栋3楼DCC水泵5.风机总报警"
WCCOActrl2:	     6: "F3P1A栋3楼DCC水泵5,风机总报警"
WCCOActrl2:	     7: "报警离开"
WCCOActrl2:	     8: "FALSE"
WCCOActrl2:	     9: "root"
WCCOActrl2:	    10: "已确认(x)"
WCCOActrl2:	    11: "grey"
*/
    string sUnit = dpGetUnit(tab[i][1]);
    stm=formatTime("%Y-%m-%d %H:%M:%S",t);
    ret[j][1]=  tab[i][1];//dpe
    ret[j][2]=  stm;//时间
    ret[j][3]=  tab[i][3];//报警级别            // short-sign
    ret[j][4]=  iPrio;                // priority
    ret[j][5]=  tab[i][5];//dpGetDescription(sDpe);             // dpe
    ret[j][6]=  SSP2;    // alert-text
    ret[j][7]=  tepy;//报警类型
    ret[j][8]=  SSP1;//(tab[i][6] == 1)?"报警来":"报警离开";                 // direction
    ret[j][9]=  (tab[i][6] == 1)?"报警来":"报警离开"; //tab[i][7] + sUnit ;  // value
    ret[j][10]= getUserName(tab[i][9]);
    ret[j][11]= sAck;   // acknowledge
    ret[j][12]=  "White";//mColor[ tab[i][11] ] ;
    //ret[j][12]= sAckStr;
    j++;
  }



  return(ret);
}


//=============================================================================
// Sort Alertscreen-table by time
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//=============================================================================
dyn_dyn_anytype sortTab(dyn_dyn_anytype &tab)
{
dyn_dyn_anytype ret;
dyn_dyn_anytype line;
int i, j, len = dynlen(tab);
time act;

  if ( len <= 2 ) return tab;  // nothing to sort
  ret[1] = tab[1];  // header
  ret[2] = tab[2];  // first line

  for (i = 3; i <= len; i++)
  {
    act = tab[i][2];
    line[1] = tab[i];  // limitation of dynInsertAt

    for (j = i-1; (j >= 2) && (act < ret[j][2]); j--) ;  // search pos to insert
    dynInsertAt(ret, line, j+1);
  }
  return ret;
}

iniColor()
{
mColor["FMCS_Object_Alert_L1_UnAcked_BackColor"]="red";
mColor["FMCS_Object_Alert_L2_UnAcked_BackColor"]="yellow";
mColor["FMCS_Object_Alert_L3_UnAcked_BackColor"]="blue";
mColor["FMCS_Object_Alert_HasUnAcked"]="red";
mColor["FMCS_Object_Alert_L1_UnAck_RTN_BackColor"]="green";
mColor["FMCS_Object_Alert_L2_UnAck_RTN_BackColor"]="green";
mColor["FMCS_Object_Alert_L3_UnAck_RTN_BackColor"]="green";
mColor["FMCS_Object_Normal_BackColor"]="grey";
mColor["FMCS_Object_Normal_Color"]= "black";
mColor["FMCS_Object_Alert_L1_UnAcked_FoerColor"]="red";
mColor["FMCS_Object_Alert_L2_UnAcked_ForeColor"]="red";
mColor["FMCS_Object_Alert_L3_UnAcked_ForeColor"]="red";
mColor["FMCS_Object_Alert_L1_Acked_BackColor"]="red";
mColor["FMCS_Object_Alert_L1_Acked_ForeColor"]="black";
mColor["FMCS_Object_Alert_L2_Acked_BackColor"]= "yellow";
mColor["FMCS_Object_Alert_L2_Acked_ForeColor"]= "black";
mColor["FMCS_Object_Alert_L3_Acked_BackColor"]= "blue";
mColor["FMCS_Object_Alert_L3_Acked_ForeColor"]= "black";
mColor["FMCS_Object_Alert_Disabled_ForeColor"]= "grey";
mColor["FMCS_Object_Alert_Disabled_BackColor"]= "grey";
mColor["FMCS_Object_Alert_Disabled_BorderColor"]= "black";
mColor["FMCS_Object_Normal_ForColor"]= "orange";
mColor["FMCS_Object_Alert_L1_UnAck_RTN_FoerColor"]= "blue";
mColor["FMCS_Object_Alert_L2_UnAck_RTN_FoerColor"]= "blue";
mColor["FMCS_Object_Alert_L3_UnAck_RTN_FoerColor"]= "blue";
mColor["默认颜色"]= "black";
mColor[" "]= "black";
mColor[""]= "black";



}



string FMCSAlertReport(dyn_string asParameter, dyn_string asValue, string sUser,string RType)
{
  //DebugN("asParameter",asParameter);
 // DebugN("asValue",asValue);
  DebugTN("Alarm报表查询开始",asValue[1]);
int     i, iErr, iPos;
time    t1, t2;         // Start and end-time
string  sT1, sT2,TX01;       // Start and end-time
string  sFilter;        // DP-Filter
string  sAction;        // Action (get-table/load-props/save-props)
int     iMaxLines;      // Maximum tablelines for each page
string  query;          // Querystring
string  from, where;    // Query-states FROM/WHERE
string  html; // HTML answer
string  sFile;          // Filename for properties
dyn_dyn_anytype tab, stab,sortedtab,tab1,tab2,tab3,tab4,tab5;   // Query-Result
dyn_dyn_string  rettab;           // Table-Lines
dyn_string  valDpList;            // DP-Filter-Liste
int         valType;              // At this Moment=1 / Closed=2
int         valState;             // Alert-State
string      valPrio= "40-100";    // Alert-Priority
bool        valTypeAlertSummary= true;
string      valShortcut;
string      valAlertText;
dyn_int     valTypeSelections;
int         row, col, pos,kk;
dyn_errClass err;
string subsystem;

for(i=1; i<=dynlen(asParameter); i++)
  // DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  iPos= dynContains(asParameter, "subsystem");
  if(iPos>0) subsystem= asValue[iPos];

  //t1= getTimeFromParameter("t1", asParameter, asValue);
  t2= getTimeFromParameter("t2", asParameter, asValue);
  iPos= dynContains(asParameter, "filter");
  if(iPos>0) sFilter= asValue[iPos];

  iPos= dynContains(asParameter, "t1");
  if(iPos>0) sT1= asValue[iPos];
  iPos= dynContains(asParameter, "t2");
  if(iPos>0) sT2= asValue[iPos];

  strreplace(sFilter, "\r", "");
  valDpList = strsplit(sFilter, "\n");
  iPos= dynContains(asParameter, "alertState");
  if(iPos>0)  valState= asValue[iPos];
  iPos= dynContains(asParameter, "timeRange");
  if(iPos>0)  valType= asValue[iPos];


  // *** Get Alert-table ***
  // Form the alert query-string
  as_getFromWhere(from, where,
                  valState, valShortcut, valPrio, valAlertText,
                  valDpList, valTypeSelections, valTypeAlertSummary, valType);
  //DebugN("from:",from);
  //TX01 = " AND "+mSQL[subsystem];
  if(subsystem=="ME")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_PEX_*,F*_PEX_*,B*_PEX_*,"
           "CUB*_CR_*,F*_CR_*,B*_CR_*,"
           "CUB*_PCW_*,F*_PCW_*,B*_PCW_*,CUB*_PV_*,F*_PV_*,B*_PV_*,CUB*_HV_*,F*_HV_*,B*_HV_*,"
           "CUB*_VOC_*,F*_VOC_*,B*_VOC_*,"
           "CUB*_NMHC_*,F*_NMHC_*,B*_NMHC_*"
         "}' ";//from;
  query += " REMOTE 'DA1:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_CUS_*,F*_CUS_*,B*_CUS_*,"
           "CUB*_GHVAC_*,F*_GHVAC_*,B*_GHVAC_*"
         "}' ";//from;
  query += " REMOTE 'DA3:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA3:'");

  dynRemove(tab2,1);
  dynAppend(tab1,tab2);
  rettab=tab1;

  }

  else if(subsystem=="GC")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*,F*,B**}' ";//from;
  query += " REMOTE 'DA2:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  rettab = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");

  }


  else if(subsystem=="Water")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_UPW_*,F*_UPW_*,B*_UPW_*}' ";//from;
  query += " REMOTE 'DA1:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA1:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{"
           "CUB*_AMT_*,F*_AMT_*,B*_AMT_*,"
           "CUB*_LK_*,F*_LK_*,B*_LK_*"
         "}' ";//from;
  query += " REMOTE 'DA4:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {
    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA4:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);





  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_WWT_*,F*_WWT_*,B*_WWT_*}' ";//from;
  query += " REMOTE 'DA5:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab3 = FMCS_ConvertAlertTab( sortedtab ,"'DA5:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);



  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PLB_*,F*_PLB_*,B*_PLB_*}' ";//from;
  query += " REMOTE 'DA3:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab4 = FMCS_ConvertAlertTab( sortedtab ,"'DA3:'");




  dynRemove(tab2,1);
  dynRemove(tab3,1);
  dynRemove(tab4,1);
  dynAppend(tab1,tab2);
  dynAppend(tab1,tab3);
  dynAppend(tab1,tab4);
  rettab=tab1;

  }

  else if(subsystem=="EE")
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PSO_*,F*_PSO_*,B*_PSO_*,"
           "CUB*_ILINE_*,F*_ILINE_*,B*_ILINE_*}' ";//from;
  query += " REMOTE 'DA4:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }




   //DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab1 = FMCS_ConvertAlertTab( sortedtab ,"'DA4:'");
  dynClear(tab);
  dynClear(stab);
  dynClear(sortedtab);






  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM '{CUB*_PMS_*,F*_PMS_*,B*_PMS_*}' ";//from;
  query += " REMOTE 'DA5:'";
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
  kk=dpQuery(query,stab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}
  uniStrReplace(from,"{","");
    uniStrReplace(from,"}","");
    uniStrReplace(from,"'","");
  //DebugN("<<<from>>>",from);
  if(from == "*" ||  from == "")
  {
    tab=stab;
  }
  else
  {

    tab[1]=stab[1];
    j=2;
      for(int i=2;i<=dynlen(stab);i++)
        if(strpos( (string)stab[i][1] , from)>=0)
        {
        tab[j] = stab[i];
        j=j+1;
      }
    }

  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  tab2 = FMCS_ConvertAlertTab( sortedtab ,"'DA5:'");


  dynRemove(tab2,1);
  dynAppend(tab1,tab2);
  rettab=tab1;

  }



  else
  {
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state','_alert_hdl.._ack_user' ";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM "+mFROM[subsystem];
  query += " REMOTE "+ mSubSystem[subsystem];
  query += " WHERE ('_alert_hdl.._prior' >= 0) "  +where;//_DP LIKE  "*CR*"
DebugN(query);
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";


  int kk=dpQuery(query,tab);
  if(kk==-1)
  {
    DebugN("dpQuery报错");
    return "";
}



  sortedtab = sortTab(tab);
  //DebugN("<<<sortedtab>>>");
  rettab = FMCS_ConvertAlertTab( sortedtab ,mSubSystem[subsystem]);
  //DebugN("<<<rettab>>>");
}

  string strCSV,inCSV;
  for (int i = 1; i <= dynlen(rettab); i++)
  {
      for (int j = 1; j <  (dynlen(rettab[i])-1); j++)
      {
      if(j!=4)
      {
        if(j==5)
        {
        uniStrReplace(rettab[i][j],".","_");
        uniStrReplace(rettab[i][j],",","_");
      }
        strCSV +=  rettab[i][j] + ",";
      }
      }
      strCSV +=  rettab[i][dynlen(rettab[i])-1] + "\n";
  }
  inCSV="DP变量名,时间,等级,报警描述,报警值,报警类型,设定值,报警方向,确认者,确认状态\n";
  strCSV=inCSV+strCSV;
  strCSV = recode(strCSV, "UTF8", "GB2312");
  string sysname,fname,st="";
  dyn_string iv;

  /*iv=strsplit(sT2,":");
  for (int i = 1; i <= dynlen(iv); i++)
  {
    st=st+iv[i];
  }
  iv=strsplit(st,".");
  st="";
  for (int i = 1; i <= dynlen(iv); i++)
  {
    st=st+iv[i];
  }
  iv=strsplit(st," ");
  st="";
  for (int i = 1; i <= dynlen(iv); i++)
  {
    st=st+iv[i];
  }*/
  st=formatTime("%Y年%m月%d日%H时",(time)sT2);

  fname="C:/Users/Administrator/Desktop/Alert/"+mpath[subsystem]+"/"+subsystem+"_"+st+"_"+RType+".csv";
  DebugN(fname);
  file fd = fopen(fname, "w+");
  if (fd==0)
  {
    fclose(fd);
    return "";
  }
  fputs(strCSV, fd);
  fflush(fd);
  fclose(fd);
  DebugTN("Alarm报表查询结束",dynlen(rettab));


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



















