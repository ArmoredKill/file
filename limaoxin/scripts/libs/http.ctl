//==============================================================================
// This Library (http.ctl) includes all functions for WinCC OA-HTML-references
// and the WinCC OA-HTTP-Server itself [ to start the Server, call:
//   HttpMain(makeDynString("")); ]
// This functions/procedures are called by the 'evalScript()'-Function.
// Also called by the HTTP-reference-callback '/PVSS' from a browser.
//
// Dirk Hegewisch 23.01.01
//==============================================================================
//
// Included functions:
// -------------------
//  - PVSS-diagnostic / System state
//    Logfile and so on (incl. Redu)
//  - Datapoint elements / View all
//    informations of a DPE (and his configs)
//  - Base-functions for HTML-References
//
//==============================================================================
// Changes: [06.03.01]-[DH]:[TI#9043: All files moved under 'data/http/']
// Changes: [30.04.01]-[DH]:[TI#9402: Insert HTML-References (new Feature)]
// Changes: [01.06.01]-[DH]:[WAP (new Feature)]
// Changes: [11.03.03]-[PK]:[WI#0207: includes now all from rs_http.ctl except
//                                    main()]
// Changes: [Date]-[Name]:[Changes]
//==============================================================================

#uses "CtrlHTTP"

#uses "dpGroups.ctl"
#uses "as.ctl"
#uses "es.ctl"
#uses "proj_http.ctl"

//=============================================================================
// Get current time
//=============================================================================
// Dirk Hegewisch   21.02.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_currentTime()
{
  return(formatTime(getCatStr("http", "formatTime", $LangId), getCurrentTime()) );
}


//=============================================================================
// Get value form config-list by parameter-name
//=============================================================================
// Dirk Hegewisch   16.02.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_getConfig(string sParameter)
{
int iPos;
  iPos= dynContains(gasConfigParameter, sParameter);
  if(iPos<1)  return("");
  return(gasConfigValue[iPos]);
}


//=============================================================================
// Get HTML-Color
//=============================================================================
// Dirk Hegewisch   01.02.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_color(string sPvssColor)
{
string sHtmlColor;

  http_getColorNameFromColorDB(sPvssColor, sHtmlColor);
  return(sHtmlColor);
}


//=============================================================================
// Get the HTML-Color out of the PVSS-Color-name
//
// Changes: [09.03.01]-[DH]:[TI9152:Error on dynAppend by empty field]
// Changes: [30.04.01]-[DH]:[TI9361:Ref-Color in blinkseq]
// Changes: [06.02.02]-[DH]:[TI13126:New Colorformat {xx,yy,zz} and Color-Alias]
// Changes: [03.09.09]-[SKLIK]:[Search all paths for colorDBs (including subprojects)]
//=============================================================================
http_getColorNameFromColorDB(string alcolor, string &htmlcolor)
{
int i;
dyn_string asColorDB;

  if(alcolor!="")
  {
    asColorDB = http_getAllProjectPaths();
    dynUnique(asColorDB);
    int iLockFile = dynContains(asColorDB, ".colorDB.lock");
    if ( iLockFile>0 )
      dynRemove(asColorDB, iLockFile);
    // if we found an ref-color or alias-color loop again [06.02.02]-[DH]
    do
    {
      htmlcolor= "";
      i= 0;
      while(htmlcolor=="" && dynlen(asColorDB)>i)
      {
        i++;
        http_searchInAllColorDB(asColorDB[i], alcolor, htmlcolor);
      }
      alcolor= htmlcolor;
    }
    while( htmlcolor!="" && strpos(htmlcolor, "#")<0 );
  }
}
//=============================================================================
// Search for ColorDBs in Project-, PVSS- and Subproject-Paths
//=============================================================================

dyn_string http_getAllProjectPaths()
{
  dyn_string retval;
  for(int i = 1; i <= SEARCH_PATH_LEN; i++)
  {
    dynAppend(retval, getFileNames(getPath(COLORDB_REL_PATH, "", 1, i), "*"));
  }
  return retval;
}

//=============================================================================
// Search for Color in ColorDB
//=============================================================================
http_searchInAllColorDB(string filename, string alcolor, string &htmlcolor)
{
file   colorDB;
string path;
string line;
int    pos;

  path = getPath(COLORDB_REL_PATH, filename);
  if(access(path,R_OK) == 0)
  {
    colorDB = fopen(path,"r");
    if(strpos(alcolor, "[") == 0 || strpos(alcolor, "{") == 0)
      sprintf(line, "\"%s\" N %s", alcolor, alcolor);
    while(!feof(colorDB))
    {
      // Search Colorname
      pos= strpos(line,alcolor);

      // Color found
      if(pos == 1)
      {
      string blinkseq, color;
      dyn_string rgb;
      int red, green, blue;
      bool   bOldCol;  // old ColorFormat [xx,yy,zz]

        // Check if ref-color in blinkseq used [21.03.01]-[DH]
        pos= strpos(line,"<\"");
        if(pos>-1)
        {
          blinkseq= substr(line, pos+2);
          pos= strpos(blinkseq, "\"");
          htmlcolor= substr(blinkseq, 0, pos);
          break;
        }

        // Get first color
        pos= strpos(line,"{");
        bOldCol= (pos<0);
        if(bOldCol)  pos= strpos(line,"[");

        blinkseq= substr(line,pos);
        pos= (bOldCol) ? strpos(blinkseq,"]") : strpos(blinkseq,"}");
        color= substr(blinkseq,1,pos-1);
        rgb= strsplit(color,",");
        red=   rgb[1];
        green= rgb[2];
        blue=  rgb[3];
        if(bOldCol)
        {
          red=   2.55 * red;
          green= 2.55 * green;
          blue=  2.55 * blue;
        }
        sprintf(htmlcolor, "#%02X%02X%02X", red, green, blue);
        break;
      }

      // Alais Color found
      if(pos == 0)
      {
        pos= strpos(line, " ")+1;
        htmlcolor= substr(line, pos, strlen(line)-pos-1);
        break;
      }

      fgets(line,99999,colorDB);
    }
    fclose(colorDB);
  }
}


//=============================================================================
// Get language- name/dirctory/Id <- from IP-Adr.
//=============================================================================
// Dirk Hegewisch   19.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_getLangName(string sIP)
{
int iPos;
  iPos= dynContains(gasIP, sIP);
  if(iPos<1)  return("");
  return(gasLangName[iPos]);
}
//--------------------------------------------------------------
string http_getLangDir(string sIP)
{
int iPos;
  iPos= dynContains(gasIP, sIP);
  if(iPos<1)  return("");
  return(gasLangDir[iPos]);
}
//--------------------------------------------------------------
int http_getLangId(string sIP)
{
int iPos;
  iPos= dynContains(gasIP, sIP);
  if(iPos<1)  return(-1);
  return(gaiLangId[iPos]);
}
//--------------------------------------------------------------
int http_setLangByName(string sIP, string sLang )
{
  int rc = 0;
  int iPos, iId;
  string sLangDir, sPath;

  // Get language-ID
  iId = getLangIdx(sLang);

  if (iId < 0 || iId == 255)
  {
    // Unknown language -> but english is valid anyway:
    if ( strpos("de", sLang) != 0 )
    {
      // it is not german. Better take english as default:
      sLang="en_US.utf8";
      iId = getLangIdx(sLang);
    }
    else
    {
      // Unknown german idiom -> change to active language:
      iId = getActiveLang();
      sLang= getLocale(iId);
    }
  }

  // Set new language
  iPos= dynContains(gasIP, sIP);
  if(iPos<1)  iPos= dynlen(gasIP)+1;
  gasIP[iPos]= sIP;
  gasLangName[iPos]= sLang;
  gaiLangId[iPos]= iId;
  sLangDir = substr(sLang, 0, strpos(sLang, "_") );
  gasLangDir[iPos]= sLangDir;
  //DebugN(gasIP, gasLangName[iPos], gaiLangId[iPos], gasLangDir[iPos]);

    // TI#9968: Check if language-dir exists
  sPath = getPath(DATA_REL_PATH, "http/" + sLangDir);
  strreplace(sPath, "\\", "/");
  strreplace(sPath, "//", "/");
  // Check if path not exists
  if(access(sPath, F_OK) == -1)
  {
    gasLangDir[iPos]= "";
    gasLangName[iPos]= "";
    rc = -1;
  }

  return( rc );
}
//--------------------------------------------------------------
time http_getLoginTime(string sIP)
{
int iPos;
  iPos= dynContains(gasLoginIP, sIP);
  if(iPos<1)  return(0);
  return(gatLoginTime[iPos]);
}
//--------------------------------------------------------------
void http_setLoginTime(string sIP)
{
int iPos;
  iPos= dynContains(gasLoginIP, sIP);
  if(iPos<1)  iPos= dynlen(gasLoginIP)+1;
  gasLoginIP[iPos]= sIP;
  gatLoginTime[iPos]= getCurrentTime();
}


//=============================================================================
// Fuction to insert an html-Refernence with replaced parameters
// [30.04.01]-[DH]:[TI#9402 (new Function)]
//=============================================================================
// Dirk Hegewisch   22.03.01
//
// Changes: [15.06.01]-[DH]:[TI#10420: By evalScript() is only '-1' an error]
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
void html_ref(string &html, string sFilename, dyn_string asDollar, int x, int y)
{
int    iErr;           // Errorhandler

  // TI#10060: Eleminate 'Ref'
  if(substr(sFilename, strlen(sFilename)-3)=="Ref")
    sFilename= substr(sFilename, 0, strlen(sFilename)-3);

  // Load reference
  iErr= html_load(html, sFilename+"Ref", $Ip);
  if(iErr<0) // Error on loading
    sprintf(html, getCatStr("http", "errFileLoad", http_getLangId($Ip)), sFilename+"Ref");
  else
  {
    // Append other usefull Parameters
    dynAppend(asDollar, "$x:"+x);
    dynAppend(asDollar, "$y:"+y);
    dynAppend(asDollar, "$User:"+$User);
    dynAppend(asDollar, "$Ip:"+$Ip);
    dynAppend(asDollar, "$LangId:"+$LangId);

    // call replace Funktion
    html_replaceParameters(html, asDollar, $Ip, $User);
  }
}
//=============================================================================
// Extract list(table) definition from HTML template file string
// string html       ... string containing startToken and endToken
// string startToken ... Start e.g. of repeating html-block
// string endToken   ... End e.g. of repeating html-block
// Extracts the characters starting with first char after startToken and
// ending with last char right before endToken.
//=============================================================================
//
//
//------------------------------------------------------------------------------
string html_extractTokenSection(string html, string startToken, string endToken)
{

 string retStr;
 int startTokenPos;
 int endTokenPos;

 retStr = "";
 startTokenPos = strpos(html,startToken);
 endTokenPos   =  strpos(html,endToken);

  if (0 > startTokenPos || 0 > endTokenPos)
   return retStr;

  retStr = substr(html,startTokenPos+strlen(startToken),(endTokenPos-startTokenPos-strlen(startToken)));

  return retStr;

}


//=============================================================================
// Replaces a section in string html beginning from startToken to EndToken
// (including startToken and endToken).
//
// string html       ... string containing startToken and endToken
// string replString ... string that should replace the specified section
// string startToken ... Start e.g. of repeating html-block
// string endToken   ... End e.g. of repeating html-block
//
//=============================================================================
//
//
//------------------------------------------------------------------------------
int html_replaceTokenSection( string &html, string replString,
                               string startToken, string endToken)
{


 int startTokenPos;
 int endTokenPos;

 string toReplacingString;

 startTokenPos = strpos(html,startToken);
 endTokenPos   = strpos(html,endToken);

 // Search found within string ??

 if (0 > startTokenPos || 0 > endTokenPos)
  return -1;

 // Get section to replace


 toReplacingString=substr(html,startTokenPos,(endTokenPos-startTokenPos+strlen(endToken)));

 return (strreplace(html,toReplacingString,replString));

}


//=============================================================================
// Search and replace parameters in list(table) definitions
//
// Start of repeating html-block: <#list_begin> or <#list_begin0> etc.
// End   of repeating html-block: <#list_end>   pr <#list_end0> etc.
//
// Substitutions per table row are done by calls to html_replaceParameters().
//
// string html                 ... string containing the HTML code from template
//                                 file.
// dyn_string tableRowName     ... place holder names in table definition.
// dyn_dyn_anytype tableValues ... table values. Place holder tableRowName[j]
//                                 is replaced by value tableValues[i][j].
// int sectNum                 ... Number of section, if multiple sections, or -1.
// string sIP, string sUser    ... see html_replaceParameters().
//
//=============================================================================
//
//
//------------------------------------------------------------------------------
int html_replaceListParameters(string &html,  dyn_string tableRowNames,
                                              dyn_dyn_anytype tableValues,
                                              int sectNum,
                                              string sIP, string sUser)
{

  string rowTemplate,rowTemplateTmp;
  string htmlTable;
  dyn_string replParams;
  int i;
  int j;
  string startSect;
  string endSect;

  // DebugN("TableRowNames:", tableRowNames);
  // DebugN("html-string:", html);

  // setTrace(NO_TRACE);

  if (sectNum < 0)
  {
    startSect="<#list_begin>";
    endSect="<#list_end>";
  }
  else
  {
    startSect="<#list_begin" + sectNum + ">";
    endSect="<#list_end" + sectNum + ">";
  }

  rowTemplate=html_extractTokenSection(html, startSect, endSect);
  rowTemplateTmp = rowTemplate;

  if (0  == strlen(rowTemplate)) return -1;

  for ( i = 1 ; i <= dynlen(tableValues); i++)
  {

    dynClear(replParams);

    for ( j=1; j <= dynlen(tableRowNames); j++)
    {
      dynAppend(replParams, tableRowNames[j] + ":" + tableValues[i][j] );

    }

    // DebugN("replParams: " + replParams );

    html_replaceParameters( rowTemplate, replParams, sIP, sUser );
    htmlTable += "\r\n" + rowTemplate;
    rowTemplate = rowTemplateTmp;
  }

 return (html_replaceTokenSection( html, htmlTable, startSect, endSect));

}



//=============================================================================
// Search and replace parameters
//=============================================================================
// Dirk Hegewisch   21.02.01
//
// Changes: [30.04.01]-[DH]:[TI#9402 New in lib - To call Ref. in Reference]
// Changes: [22.06.01]-[DH]:[TI#10061: By '?' check for aliasname]
// Changes: [12.11.01]-[DH]:[TI#12379: Error- Point at System-Name '.:']
//------------------------------------------------------------------------------
void html_replaceParameters(string &html, dyn_string asDollar,
                            string sIP, string sUser)
{
int    i, j, k;
time   t;         // Temp. time
string s;         // Temp. string
int    iErr;      // Errorhandler
bool   bCheck;    // Script syntax check
string sPara;     // Parameter from HTML-Reference
string sReplace;  // Parameterstring to be Replaced
string sResult;   // Result-Value for Parameter
char   c;
int    iPos;      // Position in parameter field
string sDollar;   // Founded $Parameter
string sText;     // Founded text
string sPoint;    // Founded point-operator
string sScript;   // Founded ctrl-script or lib.-function
string sError;    // Not interpretable parameter-part
string sDPE;      // DPE and config for getting DPE value
string sAlias;    // Alias-name of datapoint
bool   bPoint;    // Point for DPE found
bool   bGetValue; // User wants the value of DPE
langString lsComment;  // DP-Comment
string sInfo;     // Information-text
int    iType;     // DP-config type check
dyn_string asSystem;  // List of Systemnames
dyn_uint   auId;      // List of System-IDs


  getSystemNames(asSystem, auId);
  // Search for PVSS-Tag (Parameter)
  sPara= html_findParameter(html, sReplace);
  while(sPara!="")
  {
    sResult= "";
    sPoint= "";
    sScript= "";
    bGetValue= false;
    // Decode parameter
    for(j=0; j<strlen(sPara); j++)
    {
      switch(sPara[j])
      {
        case '$':  // $Parameter founded
          sDollar= "";
          while( (j+1)<strlen(sPara) && (
                 (sPara[j+1]>='a' && sPara[j+1]<='z') ||
                 (sPara[j+1]>='A' && sPara[j+1]<='Z') ||
                 (sPara[j+1]>='0' && sPara[j+1]<='9') ||
                 (sPara[j+1]=='_') ) )
          {
            j++;
            sDollar+= sPara[j];
          }
          k=1;
          while( k<=dynlen(asDollar) && strpos(asDollar[k], sDollar)!=1 )
            k++;
          if( k<=dynlen(asDollar) )
          {
            iPos= strpos(asDollar[k], ":");
            sResult+= substr(asDollar[k], iPos+1);
          }
          else
          {
            sprintf(sInfo, getCatStr("http", "errNo$Para", http_getLangId(sIP)), sDollar);
            sResult+= sInfo;
          }
        break;
        case '\"': // " Text founded
          sText= "";
          while( (j+1)<strlen(sPara) && sPara[j+1]!='\"' ) //"
          {
            j++;
            sText+= sPara[j];
          }
          j++;
          sResult+= sText;
        break;
        case '.':  // Point-operator founded
          while( (j+1)<strlen(sPara) && (
                 (sPara[j+1]>='a' && sPara[j+1]<='z') ||
                 (sPara[j+1]>='A' && sPara[j+1]<='Z') ||
                 (sPara[j+1]>='0' && sPara[j+1]<='9') ||
                 (sPara[j+1]=='_') ) )
          {
            j++;
            sPoint+= sPara[j];
          }
        break;
        case '=':  // Script for evaluation found
          j++;
          sScript= substr(sPara, j, strlen(sPara)-j);
          j= strlen(sPara);
        break;
        case '+':  // Ignore concatenations
        case ' ':  // and blanks
        break;
        case '?':  // User wants the value of DPE
          bGetValue= (j==0);
          if(bGetValue) break;
        default:
          sError= "";
          while( (j)<strlen(sPara) && (
                 (sPara[j]!='\"' && sPara[j]!='+' &&
                  sPara[j]!='.'  && sPara[j]!='\n')  ) ) //"
          {
            sError+= sPara[j];
            j++;
          }
          j--;
          sprintf(sInfo, getCatStr("http", "errUnknowPara", http_getLangId(sIP)), sError);
          sResult+= sInfo;
      } // off switch characters
    } // off for Interpetiere Paramter

    if(bGetValue)  // User wants the value of DPE
    {
      // Make DPE out of result
      sDPE= sResult;
      // [12.11.01]-[DH]:[TI#12379: Get last ':']
      j= strlen(sDPE)-1;
      while(j>0 && sDPE[j]!=':')  j--;
      if(j>0)
        if(dynContains(asSystem, substr(sDPE,0,j)) > 0)  j=0;

      // Check for alais-name (TI#10061)
      sAlias= (j>0) ? substr(sDPE,0,j) : sDPE;
      sAlias= dpAliasToName(sAlias);
      if(sAlias!="")
      {
        sAlias= dpSubStr(sAlias, DPSUB_DP_EL);
        sDPE= (j>0) ? sAlias+substr(sDPE,j) : sAlias;
      }

      // append point if usefull
      if(j>0 && sAlias=="")
      {
        bPoint= false;
        k= j;
        while(k>0 && bPoint==0)
        {
          bPoint= (sDPE[k]=='.');
          k--;
        }
        if(!bPoint)
          sDPE= substr(sDPE,0,j)+"."+substr(sDPE,j);
      }
      if(strpos(sDPE, ".")<0)
        sDPE+= ".";

      if(dpExists(sDPE) && (j>0 || sPoint!="" ) )
      {
        switch(sPoint)
        {
          case "":            // Normal dpGet of DPE
            // Check if dp-config not exists
            s= dpSubStr(sDPE, DPSUB_SYS_DP_EL_CONF);
            strreplace(s, "online",  "original");
            strreplace(s, "offline", "original");
            dpGet(s+".._type", iType);
            if(iType==DPCONFIG_NONE)
            {
              sprintf(sInfo, getCatStr("http", "errNoDpConfig", http_getLangId(sIP)),
                             dpSubStr(sDPE, DPSUB_CONF), dpSubStr(sDPE, DPSUB_DP_EL) );
              sResult= sInfo;
            }
            else  // Get result-value
            {
              dpGet(sDPE, sResult);
            }
          break;
          case "alias":       // Get dp-alias
            sResult= dpGetAlias(sDPE);
          break;
          case "comment":     // Get dp-comment
            lsComment= dpGetComment(sDPE);
            sResult= lsComment[http_getLangId(sIP)];
          break;
          case "value":       // Get dp-value with format and unit
          {
          anytype aValue;
            dpGet(sDPE+":_online.._value", aValue);
            sResult= dpValToString(sDPE, aValue, true);
          }
          break;
          case "dateTime":    // Get dp-time with local-format
            dpGet(sDPE+":_online.._stime", t);
            sResult= formatTime(getCatStr("http", "formatTime", http_getLangId(sIP)), t,
                           getCatStr("http", "formatTimeMilli", http_getLangId(sIP)) );
          break;
          case "alertColor":  // Get alertColor as HTML-Color
            dpGet(sDPE+":_alert_hdl.._type", iType);
            if(iType==DPCONFIG_NONE)
            {
              sprintf(sInfo, getCatStr("http", "errNoDpConfig", http_getLangId(sIP)),
                             "_alert_hdl", sDPE);
              sResult= ""; // sInfo;
            }
            else
            {
              dpGet(sDPE+":_alert_hdl.._act_state_color", s);
              if(s=="") s="[80,80,80]";
              http_getColorNameFromColorDB(s, sResult);
            }
          break;
          case "color":       // Get color from dp-value-string
            dpGet(sDPE+":_online.._value", s);
            http_getColorNameFromColorDB(s, sResult);
          break;
          default:          // Error unkown point-operator
            sprintf(sInfo, getCatStr("http", "errUnknowPoint", http_getLangId(sIP)), sPoint);
            sResult= sInfo;
        }
      }
      else if(dpExists(sDPE))  // Get dp-value with format and unit
      {
      anytype aValue;
        dpGet(sDPE+":_online.._value", aValue);
        sResult= dpValToString(sDPE, aValue, true);
      }
      else  // DP does not exists
      {
        sprintf(sInfo, getCatStr("http", "errDpNotExist", http_getLangId(sIP)), sDPE);
        sResult= sInfo;
      }
    } // user wants DPE value

    // Check if a script or a lib-Function to evaluate
    if(sScript!="")
    {
      // A whole script ist given
      if(strpos(sScript, "{")==0)
      {
        sScript= "string main()\n"+sScript+"\n";
      }
      // Only one library-function is called
      else
      {
        sScript= "string main(){\n"+
                 "string sReturn;\n"+
                 "  sReturn= "+sScript+";\n"+
                 "  return(sReturn);\n"+
                 "}\n";
      }

//DebugN("Script:", sScript);
      // Check script syntax
      bCheck= checkScript(sScript);
      // Do the script evaluation
      if(bCheck)
        iErr= evalScript(sResult, sScript, asDollar);
//DebugN("After eval():",iErr, sResult);

      // Error: syntax or while evaluate
      // TI#10420: Only -1 is an error
      if(iErr==-1  || !bCheck)
      {
        if(bCheck)
          sprintf(sInfo, getCatStr("http", "errEvaluate", http_getLangId(sIP)),
                  "<pre>"+sScript+"</pre>");
        else
          sprintf(sInfo, getCatStr("http", "errSyntax", http_getLangId(sIP)),
                  "<pre>"+sScript+"</pre>");
        sResult= sInfo;
      }
    }
    // Set the result into the HTML-refernce
    strreplace(html, sReplace, sResult);
    // Search for next parameter
    sPara= html_findParameter(html, sReplace);
  } // off while parameter

  // Error in find parameter
  if(sReplace!="")
  {
    // Throw error to site
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)),
                    getCatStr("http", sReplace, http_getLangId(sIP)) );
  }
}


//=============================================================================
// Base functions to create HTML site-code
//=============================================================================
void html_start(string &html, string title)
{
  html = "<html><head><title>" + title + "</title></head>\n" +
         "<body bgcolor=\"c0c0c0\"><font face=\"arial\">\n";
}
//--------------------------------------------------------------
void html_end(string &html)
{
  html += "</font></body></html>";
}
//--------------------------------------------------------------
void html_info(string &html, string sTitle, string sText)
{
  html_start(html, sTitle);
  html += "<center><b>"+sText+"</b></center>";
  html_end(html);
}
//--------------------------------------------------------------
void html_tableStart(string &html)
{
  html += "<center><table BORDER WIDTH=\"100%\" NOSAVE bgcolor=\"c0c0c0\">\n";
}
//--------------------------------------------------------------
void html_tableEnd(string &html)
{
  html += "</table></center>\n";
}
//--------------------------------------------------------------
void html_tableRowStart(string &html)
{
  html += "<tr>";
}
//--------------------------------------------------------------
void html_tableRowEnd(string &html)
{
  html += "</tr>\n";
}
//--------------------------------------------------------------
void html_tableCell(string &html, anytype value, string color)
{
string val = value;

  if(val=="")  val= "-";
  html += "<td";
  if(color)  html += " bgcolor=\"" + color + "\"";
  html += "><FONT SIZE=2>" +val + "</td>\n";
}
//--------------------------------------------------------------
void html_tableAckCell(string &html, anytype value, string datapoint, string altime, bool refresh)
{
dyn_string timeparts;
string val = value;
string day, hour;

  html += "<td align=center>";
  if(strpos(val,"!") > -1)
  {
    timeparts = strsplit(altime," ");
    day = timeparts[1];
    hour = timeparts[2];

    html += "<a href=/Acknowledge?dp=" + datapoint + "&day=" + day + "&hour=" + hour +
            "&refresh=" + refresh + " target=\"info\" " +
            "onClick=\"window.open('', 'info','width=450,height=150');\">" +
            "<FONT SIZE=2 FACE=\"Arial\">" + val + "</a>";
  }
  else
  {
    html += "<FONT SIZE=2 FACE=\"Arial\">" + val;
  }
  html += "</td>\n";
}
//--------------------------------------------------------------

//=============================================================================
// Base functions to create WML site-code (WAP)
//=============================================================================
void wml_start(string &wml, string sTitle, string sCard, string sAlign)
{
  wml = "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n" +
        "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DTD/wml_1.1.xml\">\n" +
        "<wml><card id=\"" + sCard + "\" title=\"" + sTitle + "\">\n";
  if(sAlign=="")
    wml += "<p>";
  else
    wml += "<p align=\"" + sAlign + "\">\n";
}
//--------------------------------------------------------------
void wml_end(string &wml)
{
  wml += "</p></card></wml>";
}
//--------------------------------------------------------------
void wml_newCard(string &wml, string sTitle, string sCard, string sAlign)
{
  wml += "</p></card>\n" +
         "<card id=\"" + sCard + "\" title=\"" + sTitle + "\">\n";
  if(sAlign=="")
    wml += "<p>";
  else
    wml += "<p align=\"" + aAlign + "\">\n";
}
//--------------------------------------------------------------
void wml_info(string &wml, string sTitle, string sText)
{
  wml_start(wml, sTitle, sTitle, "center");
  strreplace(wml, "<wml>",
             "<wml>\n<template>"+
             "<do type=\"go\" label=\"OK\"><prev/></do>\n"+
             "</template>");
  wml += sText+"<br/>\n";
  wml += "<a href=\"/PVSS_WAP?ref=index.wml\">OK</a>";
  wml_end(wml);
}


//=============================================================================
// Save an HTML-Site
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function saves an HTML-Site 'html' with the filename 'sFilename'.
//
// Parameter:
//        html :  string   HTML-Site to save
//   sFilename :  string   Filename
//  Ret. value :  int      Errorcode (0= Success)
//
// Sample:
// int iErr;
//    iErr= html_save(html, "result/page_17.html");
//
// Changes: [15.03.01]-[MH]:[TI 9168: Subdir http unter Linux wird nicht angelegt] (mkdir "-p" eingef�gt)
// Changes: [06.03.01]-[DH]:[TI#9040: Create non existing paths]
//------------------------------------------------------------------------------
int html_save(string html, string sFilename, string sIP)
{
int i;
string sPath;
file   dataFile;    // Data-file handling

  sFilename= DATA_PATH+"http/"+http_getLangDir(sIP)+"/"+sFilename;
  strreplace(sFilename, "\\", "/");
  strreplace(sFilename, "//", "/");

  // Get path
  i= strlen(sFilename);
  while(i>0 && sFilename[i-1]!='/') i--;
  sPath= substr(sFilename, 0, i-1);

  // Check if path not exists
  if( access(sPath, F_OK) == -1 )
  {
    // Create directory
    if(_WIN32)
    {
      strreplace(sPath, "/", "\\");
      system("cmd /c md "+sPath);
    }
    else if(_UNIX)
    {
      strreplace(sPath, "\\", "/");
      system("mkdir -p "+sPath);
    }
  }

  // Open file
  dataFile= fopen(sFilename, "w");
  if (ferror(dataFile)) // On file-error
  {
    DebugN("File error: #"+ferror(dataFile)+" in file: "+sFilename);
    // Close file
    fclose(dataFile);
    return(-1);         // Return error-code #-1
  }
  fputs(html, dataFile);

  // Close file
  fclose(dataFile);
  return(0);       // Success
}


//=============================================================================
// Load an HTML-Site
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function loads an HTML-Site 'html' as string with the filename 'sFilename'.
//
// Parameter:
//        html :  string   Loaded HTML-string
//   sFilename :  string   Filename
//  Ret. value :  int      Error-code (0= Erfolg)
//
// Sample:
// int iErr;
//    iErr= html_load(html, "es/es_base.html", sIP);
//
// Changes: [22.02.01]-[DH]:[Change to function 'fileToString()']
// Changes: [11.02.02]-[DH]:[TI#12942: Error-Code '-2'  if File not exists]
//------------------------------------------------------------------------------
int html_load(string &html, string sFilename, string sIP)
{
bool b;

  html= "";
  sFilename= getPath(DATA_REL_PATH, "http/"+http_getLangDir(sIP)+"/"+sFilename);
  if(sFilename=="")  return(-2);
  strreplace(sFilename, "\\", "/");
  strreplace(sFilename, "//", "/");

  // Load file into string
  b= fileToString(sFilename, html);
  if(!b)  // Return error-code #-1
  {
    DebugN("File error by loading file: "+sFilename);
    return(-1);
  }
  return(0);  // Success
}


//=============================================================================
// Delete an HTML-Fileset
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function deletes HTML-Site(s) of the given File-set
//
// Parameter:
//    sFileset :  string   File-set
//
// Sample:
//    html_delete("es/result/page_a*.html", sIP);
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
html_delete(string sFileset, string sIP)
{
  sFileset= DATA_PATH+"http/"+http_getLangDir(sIP)+"/"+sFileset;
  if(dynlen( getFileNames(sFileset) )>0)
  {
    if(_WIN32)
    {
      strreplace(sFileset, "/", "\\");
      system("cmd /c del "+sFileset);
    }
    else if(_UNIX)
    {
      strreplace(sFileset, "\\", "/");
      system("rm "+sFileset);
    }
  }
}

//=============================================================================
// Forward an HTML-Site
//=============================================================================
// Dirk Hegewisch   19.01.01
// Makes an automaticly forward HTML-Site
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string html_forward(string sFile, int iDelay, string sIP)
{
  return("<HTML><HEAD>\n"+
         "<meta http-equiv='refresh' content='"+iDelay+"; "+
         "URL=data/http/"+http_getLangDir(sIP)+"/"+sFile+"'>\n"+
         "</HEAD></HTML>" );
}
string html_forwardRef(string sFile, int iDelay, string sIP)
{
  return("<HTML><HEAD>\n"+
         "<meta http-equiv='refresh' content='"+iDelay+"; "+
         "URL=/PVSS?ref="+sFile+"'>\n"+
         "</HEAD></HTML>" );
}


//=============================================================================
// Search for next PVSS-Statement in HTML-String
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function searchs for the next PVSS-statement in the given HTML-string
// and returns the PVSS-statement also the part of string witch have to replaced.
//
// Parameter:
//        html :  string      Html reference-site
//  Ret. value :  string      Founded PVSS-parameter
//    sReplace :  string      String to replace
//
// Sample:
// string sParameter, sReplace;
//    sParameter= html_findParameter(html, sReplace);
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string html_findParameter(string &html, string &sReplace)
{
string sStartTag= "<%";
string sEndTag=   "%>";
int    iStart, iEnd;
string sPara;        // found Parameter

  iStart= strpos(html, sStartTag);
  iEnd=   strpos(html, sEndTag);
  if(iStart<0 || iEnd<0 || iEnd<iStart)
  {
    if(iStart<0 && iEnd<0) // No more parameters found
      sReplace= "";
    else if(iStart<0) // No end but start found
      sReplace= "errNoStartTag";
    else if(iEnd<0)   // No start but end found
      sReplace= "errNoEndTag";
    else              // End before start found
      sReplace= "errEndStart";
    return("");
  }
  iStart += strlen(sStartTag);
  sPara= substr(html, iStart, iEnd-iStart);
  sReplace= sStartTag+sPara+sEndTag;
  return(sPara);
}


//=============================================================================
// Diagnostic page / procedures
// Marc Haslop   29.01.01
//=============================================================================

//=============================================================================
// Called from http_diagnBasic
// Check out const
//=============================================================================
// Marc Haslop   29.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnConst( string &html )
{
string     sVersion;
string     sPath;
dyn_string dsPath;
string     sProjName;


  // Init vars
  html      = "";
  sVersion  = VERSION;
  sPath     = PROJ_PATH;

  strreplace( sPath, "\\", "/" );
  dsPath = strsplit( sPath, "/" );
  sProjName = dsPath[ dynlen( dsPath ) ];

  html = "<p align=\"center\"><font face=\"Arial\">\n" +
         getCatStr( "http", "version", $LangId ) + sVersion + "<br>\n" +
         getCatStr( "http", "projekt", $LangId ) + sProjName + "<br>\n" +
         getCatStr( "http", "time", $LangId ) +
         formatTime(getCatStr("http", "formatTime", $LangId), getCurrentTime() ) +
         "\n</font></p>\n";
}


//=============================================================================
// Called from diagnostics html page
// Get PVSS basic-data
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [06.02.02]-[DH]:[TI#13438: Hostname not existend on first start]
//------------------------------------------------------------------------------
http_diagnBasic( string &html )
{
int        iHostNum;
bool       bRedu;

string     sThisStatus;
string     sOtherStatus;
string     sDp;
dyn_string dsDpHarddiscs;
string     sDevice;
long        iTotal;
long        iFree;
int        iFreePerc;
bool       bErr;
string     sData1;
string     sData2;
string     sMyHostName;
string     sOtherHostName;
string     sUserId;
int        n;


  // Check if we are redundant
  iHostNum = initHosts();
  bRedu = (iHostNum>0);
  // Copy Hostname to host1 we are redundant
  if(!bRedu)  host1= hostname;

  // Table header
  if( !bRedu )
    html = "<tr>\n" +
           "<td align=\"center\" colspan=\"2\"><font size=\"4\" face=\"Arial\"><strong>" +
           getCatStr( "http", "basicInfo", $LangId ) + "</strong></font></td>\n" +
           "<td><font face=\"Arial\">" + getCatStr( "http", "singleHost", $LangId ) + "</font></td>\n" +
           "</tr>\n";
  else
    html = "<tr>\n" +
           "<td align=\"center\" colspan=\"2\"><font size=\"4\" face=\"Arial\"><strong>" +
           getCatStr( "http", "basicInfo", $LangId ) + "</strong></font></td>\n" +
           "<td><font face=\"Arial\">" + getCatStr( "http", "reduHost1", $LangId ) + "</font></td>\n" +
           "<td><font face=\"Arial\">" + getCatStr( "http", "reduHost2", $LangId ) + "</font></td>\n" +
           "</tr>\n";

  // Hostnames
  html += "<tr>\n" +
          "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "hostname", $LangId ) +
          "</strong></font></td>\n" +
          "<td><p align=\"center\"><img src=\"/pictures/http/host.gif\"></p>\n" +
          "</td>\n" +
          "<td><p align=\"center\"><font face=\"Arial\">" + host1 + "</font></p>\n" +
          "</td>\n";

  if( bRedu )
    html += "<td><p align=\"center\"><font face=\"Arial\">" + host2 + "</font></p>\n" +
            "</td>\n";

  html += "</tr>\n";


  // Redu error-level
  if( bRedu )
  {
    http_diagnBasicRedustatus( sThisStatus,
                               sOtherStatus );

    html += "<tr>\n" +
            "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "errorLevel", $LangId ) +
            "</strong></font></td>\n" +
            "<td><p align=\"center\"><img src=\"/pictures/http/error.gif\"></p>\n" +
            "</td>\n" +
            "<td><p align=\"center\"><font face=\"Arial\">" + sThisStatus + "</font></p>\n" +
            "</td>\n" +
            "<td><p align=\"center\"><font face=\"Arial\">" + sOtherStatus + "</font></p>\n" +
            "</td>\n" +
            "</tr>\n";
  }


  // Free ram
  sDp = "_MemoryCheck";
  http_diagnBasicSpaceRam( sDp,
                           iTotal,
                           iFree,
                           iFreePerc );

  html += "<tr>\n" +
          "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "freeRam", $LangId ) +
          "</strong></font></td>\n" +
          "<td><p align=\"center\"><img src=\"/pictures/http/ram.gif\"></p>\n" +
          "</td>\n" +
          "<td><p align=\"center\"><font face=\"Arial\">" + iFree + " MB / " + iTotal +
          " MB =&gt; " + iFreePerc + " %</font></p>\n" +
          "</td>\n";

  if( bRedu )
  {
    sDp = "_MemoryCheck_2";
    http_diagnBasicSpaceRam( sDp,
                             iTotal,
                             iFree,
                             iFreePerc );

    html += "<td><p align=\"center\"><font face=\"Arial\">" + iFree + " MB / " + iTotal +
            " MB =&gt; " + iFreePerc + " %</font></p>\n" +
            "</td>\n";
  }

  html += "</tr>\n";


  // HD space
  dsDpHarddiscs = dpNames( "*", "_DiskSpaceCheck" );
  for( n = 1; n <= dynlen( dsDpHarddiscs ); n ++ )
  {
    if( strpos( dsDpHarddiscs[n], "_2" ) < 0 )
    {
      // The dp ends not with "_2" => we got a dp for this host
      http_diagnBasicSpaceHd( dsDpHarddiscs[n],
                              sDevice,
                              iTotal,
                              iFree,
                              iFreePerc,
                              bErr );
      if( !bErr )
        html += "<tr>\n" +
                "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "hdSpace", $LangId ) +
                "</strong></font></td>\n" +
                "<td><p align=\"center\"><img src=\"/pictures/http/hd.gif\"></p>\n" +
                "</td>\n" +
                "<td>\n" +
                "<align=\"center\"><font size=\"2\" face=\"Arial\">" + sDevice + "</font>\n" +
                "<br>\n" +
                "<align=\"center\"><font face=\"Arial\">" + iFree + " MB / " + iTotal +
                " MB =&gt; " + iFreePerc + " %</font>\n" +
                "</td>\n";
    }

    if( bRedu )
    {
      if( strpos( dsDpHarddiscs[n], "_2" ) == strlen( dsDpHarddiscs[n] ) -2 )
      {
        // The dp ends with "_2" => we got a dp for the other redu host
        http_diagnBasicSpaceHd( dsDpHarddiscs[n],
                                sDevice,
                                iTotal,
                                iFree,
                                iFreePerc,
                                bErr );
        if( !bErr )
        {
          html += "<td>\n" +
                  "<align=\"center\"><font size=\"2\" face=\"Arial\">" + sDevice + "</font>\n" +
                  "<br>\n" +
                  "<align=\"center\"><font face=\"Arial\">" + iFree + " MB / " + iTotal +
                  " MB =&gt; " + iFreePerc + " %</font>\n" +
                  "</td>\n";

          html += "</tr>\n";
        }
      } // End "_2"
    } // End redu

    else
    {
      // Set the last element when not redu
      if( !bErr )
        html += "</tr>\n";
    }
  } // End loop dps


  // Activated by DH 05.07.01
  // System runtime
  http_diagnBasicRuntime( bRedu,
                          sData1,
                          sData2 );

  html += "<tr>\n" +
          "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "systemRuntime", $LangId ) +
          "</strong></font></td>\n" +
          "<td><p align=\"center\"><img src=\"/pictures/http/time.gif\"></p>\n" +
          "</td>\n" +
          "<td><p align=\"center\"><font face=\"Arial\">" + sData1 + "</font></p>\n" +
          "</td>\n";

  if( bRedu )
    html += "<td><p align=\"center\"><font face=\"Arial\">" + sData2 + "</font></p>\n" +
            "</td>\n";

  html += "</tr>\n";


  // NT system file
  if( _WIN32 )
  {
    html += "<tr>\n" +
            "<td align=\"center\"><font face=\"Arial\"><strong>" + getCatStr( "http", "ntSystem", $LangId ) +
            "</strong></font></td>\n" +
            "<td><p align=\"center\"><img src=\"/pictures/http/ntSystem.gif\"></p>\n" +
            "</td>\n" +
            "<td><p align=\"center\"><a onClick=\"window.open('', 'download','width=300,height=300');\"\n" +
            "href=/PVSS?ref=/diagnostics/download.html&cbLogfile1=" +
            host1 + "&countItems=1 target=\"download\">\n" +
            "<font face=\"Arial\">" + host1 + ".txt</font></a></td>\n";

    if( bRedu )
      html += "<td><p align=\"center\"><a onClick=\"window.open('', 'download','width=300,height=300');\"\n" +
              "href=/PVSS?ref=/diagnostics/download.html&cbLogfile1=" +
              host2 + "&countItems=1 target=\"download\">\n" +
              "<font face=\"Arial\">" + host2 + ".txt</font></a></td>\n";

    html += "</tr>\n";
  }
}
//=============================================================================
// Called from diagnostics wml page
// Get PVSS basic-data
//=============================================================================
// Dirk Hegewisch   01.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnWap( string &wml )
{
int        iHostNum;
bool       bRedu;

string     sDp;
dyn_string dsDpHarddiscs;
string     sDevice;
long        iTotal;
long        iFree;
int        iFreePerc;
bool       bErr;
int        n;
string     sHost;
int        iStatus;


  // Check if we are redundant
  iHostNum = initHosts();
  bRedu= (iHostNum > 0);

  // HD space
  dsDpHarddiscs[1]= "_ArchivDisk";
  if(bRedu) dsDpHarddiscs[2]= "_ArchivDisk_2";
  for( n = 1; n <= dynlen( dsDpHarddiscs ); n ++ )
  {
    http_diagnBasicSpaceHd( dsDpHarddiscs[n],
                            sDevice,
                            iTotal,
                            iFree,
                            iFreePerc,
                            bErr );
    if( !bErr )
      wml += getCatStr( "http", "hdWap", $LangId ) + " " + n + ":<br/><b>" + iFreePerc + "% </b> " +
             getCatStr( "http", "avail", $LangId ) + "<br/>\n";
  } // End loop dps

  // Free ram
  sDp = "_MemoryCheck";
  http_diagnBasicSpaceRam( sDp,
                           iTotal,
                           iFree,
                           iFreePerc );
  wml += getCatStr( "http", "ramWap", $LangId ) + ":<br/><b>" + iFreePerc + "% </b> " +
         getCatStr( "http", "avail",  $LangId ) + "<br/>\n";

  // witch host is active
  if(bRedu)
  {
    getReduHost(sHost, iStatus, true);
    wml += getCatStr( "http", "activeHost", $LangId ) + ":<br/>" +
           "<b>" + sHost + " (" + iStatus + ")</b><br/>\n";
  }

  // append current time
  wml += getCatStr( "http", "dateTime", $LangId ) + ":<br/>" +
         "<b>" + http_currentTime() + "</b><br/>\n";
}


//=============================================================================
// Called from http_diagnBasic
// Check out redu error numbers
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnBasicRedustatus( string &sThisStatus,
                           string &sOtherStatus )
{
int      iThisStatus;
int      iOtherStatus;
int      iHostNum;
unsigned uValue1, uValue2, uValue3, uValue4;


  iHostNum = initHosts();
  if( iHostNum <= 0 )
  {
    // NO REDUNDANZ
    sThisStatus  = "0";
    sOtherStatus = "0";
    return;
  }

  if( iHostNum == 1 )
  {
    dpGet( "_ReduManager.MyErrorStatus:_online.._value",   iThisStatus );
    dpGet( "_ReduManager.PeerErrorStatus:_online.._value", iOtherStatus );
  }

  else if( iHostNum == 2 )
  {
    dpGet( "_ReduManager_2.PeerErrorStatus:_online.._value", iThisStatus );
    dpGet( "_ReduManager_2.MyErrorStatus:_online.._value",   iOtherStatus );
  }

  else
  {
    // Decentral UI
    dpGet( "_ReduManager.MyErrorStatus:_online.._value",     uValue1,
           "_ReduManager.PeerErrorStatus:_online.._value",   uValue2,
           "_ReduManager_2.MyErrorStatus:_online.._value",   uValue3,
           "_ReduManager_2.PeerErrorStatus:_online.._value", uValue4 );

    // This
    if( uValue2 == -1 )
      iThisStatus = uValue1;
    else
      iThisStatus = uValue4;

    // Other
    if( uValue4 == -1 )
      iOtherStatus = uValue3;
    else
      iOtherStatus = uValue2;
  }


  // Check if system is available
  if( iThisStatus != -1 )
    sThisStatus = iThisStatus;
  else
    sThisStatus = getCatStr( "http", "systemNotAvailable", http_getLangId( $Ip ));

  if( iOtherStatus != -1 )
    sOtherStatus = iOtherStatus;
  else
    sOtherStatus = getCatStr( "http", "systemNotAvailable", http_getLangId( $Ip ));
}


//=============================================================================
// Called from http_diagnBasic
// Check out space from RAM
//=============================================================================
// Marc Haslop   26.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnBasicSpaceRam( string  sDp,
                         long    &iTotal,
                         long    &iFree,
                         int    &iFreePerc )
{
  dpGet( sDp + ".TotalKB:_online.._value",  iTotal,
         sDp + ".FreeKB:_online.._value",   iFree,
         sDp + ".FreePerc:_online.._value", iFreePerc );

  if(( iTotal > 0 ) && ( iFree > 0 ))
  {
    iTotal    = iTotal / 1024;
    iFree     = iFree  / 1024;
  }
}


//=============================================================================
// Called from http_diagnBasic
// Check out space from hard disks
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnBasicSpaceHd( string  sDp,
                        string &sDevice,
                        long    &iTotal,
                        long    &iFree,
                        int    &iFreePerc,
                        bool   &bErr )
{
  if( dpExists( sDp ))
  {
    dpGet( sDp + ".Device:_online.._value",   sDevice,
           sDp + ".TotalKB:_online.._value",  iTotal,
           sDp + ".FreeKB:_online.._value",   iFree,
           sDp + ".FreePerc:_online.._value", iFreePerc );

    if( sDevice != "" )
    {
      if(( iTotal > 0 ) && ( iFree > 0 ))
      {
        iTotal    = iTotal / 1024;
        iFree     = iFree  / 1024;
        bErr = false;
      }
      else
        bErr = true;
    }
    else
      bErr = true;
  }
  else
    bErr = true;
}


//=============================================================================
// Called from http_diagnBasic
// Check out Runtime
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [05.07.01]-[DH]:[TI#10541: Changes on _Connections-DP]
//------------------------------------------------------------------------------
http_diagnBasicRuntime( bool    bRedu,
                        string &sData1,
                        string &sData2 )
{
dyn_time atData;

  dpGet("_Connections.Data.StartTimes:_online.._value", atData);
  sData1 = formatTime(getCatStr("http", "formatTime", $LangId), atData[1]);

  if(bRedu)
  {
    dpGet("_Connections_2.Data.StartTimes:_online.._value", atData);
    sData2 = formatTime(getCatStr("http", "formatTime", $LangId), atData[1]);
  }
  else
    sData2 = "";
}


//=============================================================================
// Called from http_diagnBasic
// Find out Hostname
//=============================================================================
// Marc Haslop   25.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnBasicHostname( string &sMyHost,
                         string &sOtherHost )
{
int iHostNum;


  iHostNum = initHosts();
  if( iHostNum == 2 )
  {
    sMyHost    = host2;
    sOtherHost = host1;
  }
  else
  {
    sMyHost    = host1;
    sOtherHost = host2;
  }
}


//=============================================================================
// Called from diagnostics html page
// Get PVSS informations about logged users
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [05.07.01]-[DH]:[TI#10541: Changes on _Connections-DP]
//------------------------------------------------------------------------------
http_diagnLogin( string &html )
{
dyn_int    diConnectionNum, diConnectionNum2;
dyn_string dsUi;
string     sUser;
time       tLogin;
string     sLogin;
int        i;


  dpGet( "_Connections.Ui.ManNums:_online.._value", diConnectionNum );
  if(dpExists( "_Connections_2.ui" ))
    dpGet( "_Connections_2.Ui.ManNums:_online.._value", diConnectionNum2 );

  dynAppend( diConnectionNum, diConnectionNum2 );
  dynUnique( diConnectionNum );
  dynSortAsc( diConnectionNum );

  for(i = 1; i <= dynlen ( diConnectionNum ); i ++ )
  {
    dsUi[i]="_Ui_" + diConnectionNum[i];
    dpGet( dsUi[i] + ".UserName:_online.._value", sUser,
           dsUi[i] + ".UserName:_online.._stime", tLogin );

    if( sUser == "" )
      sUser = "---";

    if( tLogin > 0 )
      sLogin = formatTime( "%d.%m.%Y %H:%M", tLogin );
    else
      sLogin = "---";

    html += "<tr>\n" +
            "<td align=\"center\"><font face=\"Arial\">" + diConnectionNum[i] + "</font></td>\n" +
            "<td><font face=\"Arial\">" + sUser + "</font></td>\n" +
            "<td><font face=\"Arial\">" + sLogin + "</font></td>\n" +
            "</tr>\n";
  }
}


//=============================================================================
// Called from diagnostics html page
// Get message informations about active managers
//=============================================================================
// Marc Haslop   23.01.01
//
//     New: [05.07.01]-[DH]:[TI#10541: Changes on _Connections-DP]
//     New: [04.02.02]-[DH]:[TI#12786: Display Hostname for each Manager]
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnManagers( string &html )
{
int i;
dyn_string asManConDpe;   // DPEs for all managers
dyn_int    aiManNums;     // List of manager numbers
dyn_time   atStartTimes;  // List of manager start-times
dyn_string asHostNames;   // List of manager host-names
string     sManType;      // Type of manager
string     htmlTemp;


  // Get all manager-type DPEs
  asManConDpe= dpNames("_Connections" +( (initHosts()==2)?"_2":"" )+ ".*", "_Connections");

  // Loop over manager-types
  for(i=1; i<=dynlen(asManConDpe); i++)
  {
    // Get active manager infos
    //
    dpGet(asManConDpe[i]+".ManNums:_online.._value",    aiManNums,
          asManConDpe[i]+".StartTimes:_online.._value", atStartTimes,
          asManConDpe[i]+".HostNames:_online.._value",  asHostNames);
    sManType= substr(asManConDpe[i], strpos(asManConDpe[i], ".")+1 );
    sManType= dcase(sManType);

    // Get manager statistics (send/recive msg.)
    diagnManActive(htmlTemp, aiManNums, atStartTimes, asHostNames, sManType);
    html += htmlTemp;
  }
}


//=============================================================================
// Subfunction from http_diagnManagers
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [05.07.01]-[DH]:[TI#10541: Changes on _Connections-DP]
//     New: [04.02.02]-[DH]:[TI#12786: Display Hostname for each Manager]
//------------------------------------------------------------------------------
string diagnManActive( string     &html,
                       dyn_int    diManNum,
                       dyn_time   dtStartTime,
                       dyn_string dsHostName,
                       string     sManName )
{
int        i, iPos;
dyn_int    diSortManNum;
dyn_time   dtSortStartTime;
dyn_string dsSortHostName;
string     sStartTime;
string     dpName;
string     sStatSnd;
string     sStatRcv;
int        iStatRefresh;


  // Init var
  html = "";

  if( dynlen( diManNum ) > 0 )
  {
    // Sort by manager number
    diSortManNum= diManNum;
    dynSortAsc(diSortManNum);
    for(i=1; i<=dynlen(diSortManNum); i++)
    {
      iPos= dynContains(diManNum, diSortManNum[i]);
      dtSortStartTime[i]= dtStartTime[iPos];
      dsSortHostName[i] = dsHostName[iPos];
    }

    // Check if statistic is active
    dpGet("_Stat_Connections_Refresh.SecsToRefresh:_online.._value", iStatRefresh);

    // Loop for all manager numbers
    for( i = 1; i <= dynlen( diSortManNum ); i ++ )
    {
      // Get data
      dpName = "_Stat_event_0_to_" + sManName + "_" + diSortManNum[i];
      if( dpExists(dpName) && iStatRefresh>0 )
      {
        dpGet( dpName + ".SndTotal:_online.._value", sStatSnd,
               dpName + ".RcvTotal:_online.._value", sStatRcv );
      }
      else
      {
        sStatSnd= "---";
        sStatRcv= "---";
      }
      sStartTime= formatTime(getCatStr("http", "formatTime", $LangId), dtSortStartTime[i]);
      html += "<tr>\n" +
              "<td align=\"center\"><font face=\"Arial\">" + sManName + "</font></td>\n" +
              "<td align=\"center\"><font face=\"Arial\">" + diSortManNum[i] + "</font></td>\n" +
              "<td align=\"center\"><font face=\"Arial\">" + dsSortHostName[i] + "</font></td>\n" +
              "<td align=\"center\"><font face=\"Arial\">" + sStartTime + "</font></td>\n" +
              "<td align=\"center\"><font face=\"Arial\">" + sStatSnd + "</font></td>\n" +  // Snd from Event
              "<td align=\"center\"><font face=\"Arial\">" + sStatRcv + "</font></td>\n" +  // Rcv to Event
              "</tr>\n";
    }
  }
}


//=============================================================================
// Called from diagnostics html page
// Get PVSS informations about Versions
//=============================================================================
// Marc Haslop   23.01.01
//
// Changes: [06.03.01]-[DH]:[TI#9042: Version-files '*.ver' moved under 'data/temp/']
// Changes: [12.11.01]-[DH]:[TI#12522: OPC-Server removed 'opcsrv']
//------------------------------------------------------------------------------
http_diagnVersions( string &html )
{
string     sProjPath;
string     sPvssPath;
string     sExtension;
dyn_string dsManager;
dyn_string dsTemp;

string     sPath;
file       f;
string     sVersion;
dyn_string dsVersion;
int        iPvssMonth;
int        iPvssDay;
int        iPvssYear;
int        iPvssHour;
int        iPvssMinute;
int        iPvssSecond;
dyn_string dsMONTH = makeDynString( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );
time       tPvssDate;
string     sPvssDate;
string     sPvssVersion;
int        n, i, iErr;


  // Init vars
  html = "";
  sProjPath = PROJ_PATH + BIN_REL_PATH;
  sPvssPath = PVSS_PATH + BIN_REL_PATH;

  // Check operating system
  if( _WIN32 )
    sExtension = ".exe";
  else
    sExtension = "";

  // IM 104586 start
  // workaround for different manager prefixes
  dyn_string dsPlatformPref = getFileNames(sPvssPath, PLATFORM_COMPONENT_PREFIX + sExtension);
  dyn_string dsPlatformTool = getFileNames(sPvssPath, PLATFORM_TOOL_COMPONENT_PREFIX + sExtension);
  dyn_string dsWinccoaPref = getFileNames(sPvssPath, WINCCOA_COMPONENT_PREFIX + sExtension);
//   dyn_string dsWinccoaTool = getFileNames(sPvssPath, WINCCOA_TOOL_COMPONENT_PREFIX + sExtension);
  dyn_string dsPlatformPrefProj = getFileNames(sProjPath, PLATFORM_COMPONENT_PREFIX + sExtension);
  dyn_string dsPlatformToolProj = getFileNames(sProjPath, PLATFORM_TOOL_COMPONENT_PREFIX + sExtension);
  dyn_string dsWinccoaPrefProj = getFileNames(sProjPath, WINCCOA_COMPONENT_PREFIX + sExtension);
//   dyn_string dsWinccoaToolProj = getFileNames(sProjPath, WINCCOA_TOOL_COMPONENT_PREFIX + sExtension);

  // remove tools from dyn_string, only components are needed
  for (int i = 1; i <= dynlen(dsPlatformTool); i++)
  {
    int iContain = dynContains(dsPlatformPref, dsPlatformTool[i]);
    dynRemove(dsPlatformPref, iContain);
  }
  // combine PVSS00 and WCCIL managers
  dynAppend(dsWinccoaPref, dsPlatformPref);
  dyn_string dsAllManagers = dsWinccoaPref;

  // do the same for project path
  for (int i = 1; i <= dynlen(dsPlatformToolProj); i++)
  {
    int iContainProj = dynContains(dsPlatformPrefProj, dsPlatformToolProj[i]);
    dynRemove(dsPlatformPrefProj, iContainProj);
  }
  dynAppend(dsWinccoaPrefProj, dsPlatformPrefProj);
  dyn_string dsAllManagersProj = dsWinccoaPrefProj;

  dynAppend(dsAllManagers, dsAllManagersProj);
  dynUnique(dsAllManagers);

  dsManager = dsAllManagers;

  // end workaround
  // IM 104586 end

  // Find out all Managers from projpath and pvsspath
//   dsTemp = getFileNames( sProjPath, "PVSS00*" + sExtension );
//   dsManager = dsTemp;
//   dsTemp = getFileNames( sPvssPath, "PVSS00*" + sExtension );
//   dynAppend( dsManager, dsTemp );
//   dynUnique( dsManager );

  for( n = dynlen( dsManager ); n > 0; n -- )
  {
    strreplace( dsManager[n], PLATFORM_COMPONENT_PREFIX, "" );
    strreplace( dsManager[n], WINCCOA_COMPONENT_PREFIX, "" );
    strreplace( dsManager[n], ".exe", "" );
    if( strpos( dsManager[n], "." ) > 0 )
      dynRemove( dsManager, n );  // Remove all files which are not matching "PVSS00.." (".so" e.g.)
  }

  // Loop manager
  for( i = 1; i <= dynlen( dsManager); i ++ )
  {
    // Some Manager don't answer when asking a version
    if( dsManager[i] == "archiv" ||
        dsManager[i] == "opcsrv" /* ||
        dsManager[i] == "blink"  ||
        dsManager[i] == "NV" ||
        dsManager[i] == "NG" ||
        dsManager[i] == "XCheck" */)
      continue;
    // Get Path
    sPath = getPath( BIN_REL_PATH, PLATFORM_COMPONENT_PREFIX + dsManager[i] + sExtension );
    if (sPath = "")
      sPath = getPath( BIN_REL_PATH, WINCCOA_COMPONENT_PREFIX + dsManager[i] + sExtension );
    // Set system command
    if( _WIN32 )
    {
      string sCmd;
      sCmd = sPath + " -version 2> " + PROJ_PATH + DATA_REL_PATH +  + "http/temp/" + dsManager[i] + ".ver";
      strreplace(sCmd,"/","\\");
      iErr = system( "cmd.exe /c " + sCmd );
    }
    else
    {
      iErr = system( sPath + " -version 2> " + PROJ_PATH + DATA_REL_PATH +  + "http/temp/" + dsManager[i] + ".ver" );
    }

    // Get destination file
    if( access( PROJ_PATH + DATA_REL_PATH + "http/temp/" + dsManager[i] + ".ver", R_OK ) == 0 )
    {
      // File is available
      f = fopen( PROJ_PATH + DATA_REL_PATH + "http/temp/" + dsManager[i] + ".ver", "r" );
      fgets( sVersion, 999, f ); // We want the first line since IM 61991
      fclose( f );

      // Check data
      if( strpos( sVersion, " linked at " ) > 0 )
      {
        // Find out link date
        strreplace( sVersion, " linked at ", "#" );
        dsVersion = strsplit( sVersion, "#" );

        iPvssMonth  = dynContains( dsMONTH, substr( dsVersion[2], 0, 3 ));
        iPvssDay    = substr( dsVersion[2], 4, 2 );
        iPvssYear   = substr( dsVersion[2], 7, 4 );
        iPvssHour   = substr( dsVersion[2], 12, 2 );
        iPvssMinute = substr( dsVersion[2], 15, 2 );
        iPvssSecond = substr( dsVersion[2], 18, 2 );
        tPvssDate   = makeTime( iPvssYear, iPvssMonth, iPvssDay,
                                iPvssHour, iPvssMinute, iPvssSecond );
        sPvssDate   = formatTime( getCatStr( "http", "formatTime", $LangId ), tPvssDate );

        // Find out link version
        dsVersion   = strsplit( dsVersion[1], ":" );
        if( dynlen( dsVersion ) >= 4 )
          sPvssVersion = dsVersion[4];
        else
          sPvssVersion = "?";
      }
      else if( strpos( sVersion, "not initialized" ) > 0 )
      {
        sPvssVersion = "?";
        sPvssDate = "not initialized";
      }
      else
      {
        sPvssVersion = "?";
        sPvssDate = "?";
      }
    }
    else
    {
      // An error occured
      sPvssVersion = "?";
      sPvssDate = "?";
    }

    html += "<tr>\n" +
            "<td align=\"center\"><font face=\"Arial\">" + dsManager[i] + "</font></td>\n" +
            "<td align=\"center\"><font face=\"Arial\">" + sPvssVersion + "</font></td>\n" +
            "<td align=\"center\"><font face=\"Arial\">" + sPvssDate + "</font></td>\n" +
            "</tr>\n";
  }
}


//=============================================================================
// Called from diagnostics html page
// Show all logfiles in PVSS project path
//=============================================================================
// Marc Haslop   24.01.01
//
// Changes: [21.06.01]-[DH]:[TI#10442: Show size of file]
//------------------------------------------------------------------------------
http_diagnLogfiles( string &html )
{
string     sLogPath;
dyn_string dsFiles;
int        n;


  // Init vars
  html = "";
  sLogPath  = PROJ_PATH + LOG_REL_PATH;

  // Read all files from log path
  dsFiles = getFileNames( sLogPath, "*" );

  // Display this files
  for( n = 1; n <= dynlen( dsFiles ); n ++ )
  {
    html += "<tr>\n" +
            "<td align=\"center\"><input type=\"checkbox\" " +
            "name=\"cbLogfile" + n + "\" value=\"" + dsFiles[n] + "\"></td>\n" +
            "<td><font face=\"Arial\">" + dsFiles[n] +
            " (" + getFileSizeString(sLogPath+dsFiles[n]) + ")</font></td>\n" +
            "</tr>\n";
  }

  // Append one item with numbers of elements (outside the table - is not visible)
  html += "<input type=\"hidden\" name=\"countItems\" value=\"" + n + "\">\n";
}


//=============================================================================
// Download page
//=============================================================================

//=============================================================================
// Called from download html page
// Check if we have to handle a NT file or PVSS log files
//=============================================================================
// Marc Haslop   29.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_diagnDownload( string &html )
{
string sUserId;
string sMyHostName;
string sOtherHostName;


  // Init vars
  html = "";
  sUserId   = $Ip;
  strreplace( sUserId, ".", "" );


  // Compare with given filename
  if(( $countItems == 1 ) && ( isDollarDefined( "$cbLogfile1" )))
  {
    // Get name of this host
    http_diagnBasicHostname( sMyHostName, sOtherHostName );

    if( sMyHostName == $cbLogfile1 )
    {
      // Create NT file
      http_diagnDownloadNtfile( sMyHostName, sUserId, html );
    }
    else if(( sOtherHostName != "" ) && ( sOtherHostName == $cbLogfile1 ))
    {
      // Create NT file
      http_diagnDownloadNtfile( sOtherHostName, sUserId, html );
    }
  }
  else
  {
    // Zip PVSS log files
    http_diagnDownloadLogfiles( sUserId, html );
  }
}


//=============================================================================
// Called from download html page
// Check given filesnames, zip and display them
//=============================================================================
// Marc Haslop   24.01.01
//
// Changes: [21.06.01]-[DH]:[TI#10442: Show size of file]
//------------------------------------------------------------------------------
http_diagnDownloadLogfiles( string  sUserId,
                            string &html )
{
string     sLogPath;
string     sDataPath;
dyn_string dsOldFiles;
dyn_string dsZipFiles;
string     sFile;
int        iCountItems;
int        n;
bool       bErr;

string     sDiagnPath;
string     sDownloadPath;


  // Init vars
  html = "";
  sLogPath  = PROJ_PATH + LOG_REL_PATH;
  sDataPath = PROJ_PATH + DATA_REL_PATH + "http/download/";
  if( _WIN32 )
    strreplace( sDataPath, "/", "\\" );


  // Delete old zip files
  dsOldFiles = getFileNames(  sDataPath + sUserId + "*.zip" );
  if( dynlen( dsOldFiles ) > 0 )
  {
    if( _WIN32 )
      system( "cmd.exe /c del " + sDataPath + sUserId + "*.zip" );
    else
      system( "rm " + sDataPath + sUserId + "*.zip" );
   }

  // Loop $-parameter
  iCountItems = $countItems;
  for( n = 1; n <= iCountItems; n ++ )
  {
    sFile = "$cbLogfile" + n;
    if( isDollarDefined( sFile ))
      dynAppend( dsZipFiles, getDollarValue( sFile ));
  }


  // Loop files to zip them
  for( n = 1; n <= dynlen( dsZipFiles ); n ++ )
  {
    // Copy files (then they become mine)
    bErr = copyFile( sLogPath + dsZipFiles[n],
                     sDataPath + sUserId + "_" + dsZipFiles[n] );

    if( bErr == true )
    {
      // Zip
      if( _WIN32 )
        bErr = system( "cmd.exe /c zip -q -j " + sDataPath + sUserId + "_" + dsZipFiles[n] + ".zip " +
                                                 sDataPath + sUserId + "_" + dsZipFiles[n] );
      else
        bErr = system( "zip -q -j " + sDataPath + sUserId + "_" + dsZipFiles[n] + ".zip " +
                                                 sDataPath + sUserId + "_" + dsZipFiles[n] );

      // Delete copied file
      if( _WIN32 )
        system( "cmd.exe /c del " + sDataPath + sUserId + "_" + dsZipFiles[n] );
      else
        system( "rm " + sDataPath + sUserId + "_" + dsZipFiles[n] );

      if( bErr == false)
      {
        // Display this file
        html += "<tr>\n" +
                "<td colspan=\"2\"><p align=\"center\">" +
                "<a href=\"/data/http/download/" + sUserId + "_" + dsZipFiles[n] + ".zip\">\n" +
                "<font face=\"Arial\">" + dsZipFiles[n] + ".zip</font></a>" +
                " (" + getFileSizeString(sDataPath+sUserId+"_"+dsZipFiles[n]+".zip") + ")</td>\n" +
                "</tr>\n";
      }
      else
      {
        // Display error
        html += "<tr>\n" +
                "<td colspan=\"2\"><p align=\"center\">\n" +
                "<font face=\"Arial\">Error: " + dsZipFiles[n] + ".zip</font></td>\n" +
                "</tr>\n";
      }
    }
    else
    {
      // Display error
      html += "<tr>\n" +
              "<td colspan=\"2\"><p align=\"center\">\n" +
              "<font face=\"Arial\">Error: " + dsZipFiles[n] + ".zip</font></td>\n" +
              "</tr>\n";
    }
  }
}


//=============================================================================
// Called from http_diagnBasic
// Create NT file
//=============================================================================
// Marc Haslop   26.01.01
//
// Changes: [21.06.01]-[DH]:[TI#10442: Show size of file]
//------------------------------------------------------------------------------
http_diagnDownloadNtfile( string  sHostName,
                          string  sUserId,
                          string &html )
{
string sDataPath;
string sDownloadPath;
string sBatchFile;
bool   bErr;


  if( !_WIN32 )
  {
    // Display error
    html += "<tr>\n" +
            "<td colspan=\"2\"><p align=\"center\">\n" +
            "<font face=\"Arial\">Error: " + sHostName + ".zip</font></td>\n" +
            "</tr>\n";
    return;
  }


  // Init vars
  html          = "";
  bErr          = false;
  sUserId       = "WIN" + sUserId;
  sDataPath     = PROJ_PATH + DATA_REL_PATH;
  sDownloadPath = PROJ_PATH + DATA_REL_PATH + "http/download/";
  sBatchFile    = getPath(DATA_REL_PATH, "http/start/winInfo.bat");

  strreplace( sUserId, ".", "" );
  strreplace( sDataPath, "/", "\\" );   // TI9398; TI12243
  strreplace( sDownloadPath, "/", "\\" );
  strreplace( sBatchFile, "/", "\\" );

  // Delete old file
  if( access( sDownloadPath + sUserId + "_" + sHostName + ".zip", R_OK ) == 0 )
      system( "cmd.exe /c del " + sDownloadPath + sUserId + "_" + sHostName + ".zip" );

  // Create new info file
  system( "cmd.exe /c " + sBatchFile + " " + sDataPath + " \\\\" + sHostName );
  if( access( sDataPath + sHostName + ".txt", R_OK ) == 0 )
  {
    // Zippen
    bErr = system( "cmd.exe /c zip -q -j " + sDownloadPath + sUserId + "_" + sHostName + ".zip " +
                                             sDataPath     + sHostName + ".txt" );
    if( !bErr )
    {
      // Display this file
      html += "<tr>\n" +
              "<td colspan=\"2\"><p align=\"center\">" +
              "<a href=\"/data/http/download/" + sUserId + "_" + sHostName + ".zip\">\n" +
              "<font face=\"Arial\">" + sHostName + ".zip</font></a>" +
              " (" + getFileSizeString(sDownloadPath+sUserId+"_"+sHostName+".zip") + ")</td>\n" +
              "</tr>\n";
    }

    // Delete an copied files
    system( "cmd.exe /c del " + sDataPath + sHostName + ".txt" );
  }
  else
    bErr = true;

  if( bErr )
  {
    // Display error
    html += "<tr>\n" +
            "<td colspan=\"2\"><p align=\"center\">\n" +
            "<font face=\"Arial\">Error: " + sHostName + ".zip</font></td>\n" +
            "</tr>\n";
  }
}


//------------------------------------------------------------------------------
// Dirk Hegewisch   22.10.98
//------------------------------------------------------------------------------
int  ascii(char zeichen) { return(zeichen); }
char chr  (int  nummer)  { return(nummer);  }

//------------------------------------------------------------------------------
// Dirk Hegewisch   22.10.98
//------------------------------------------------------------------------------
string ucase(string text)
{
string erg;  // Ergebnis Text
char   c;    // Zeichen
int    i;

  for(i=0; i<strlen(text); i++)
  {
    c= text[i];
    // Pr�fen ob das Zeichenumzuwandeln ist
    if( ((c>='a')&&(c<='z')) || (c>=224) )
      c = chr(ascii(c)-32);
    erg += c;
  }
  return(erg);
}

//------------------------------------------------------------------------------
// Dirk Hegewisch   22.10.98
//------------------------------------------------------------------------------
string dcase(string text)
{
string erg;  // Ergebnis Text
char   c;    // Zeichen
int    i;

  for(i=0; i<strlen(text); i++)
  {
    c= text[i];
    // Pr�fen ob das Zeichenumzuwandeln ist
    if( ((c>='A')&&(c<='Z')) || ((c>=192)&&(c<=222)) )
      c = chr(ascii(c)+32);
    erg += c;
  }
  return(erg);
}


//=============================================================================
// Get (in)active reduhost and error-level
//=============================================================================
// Dirk Hegewisch   05.06.01
//
// bActive = (true > get active host; false > get inactive host)
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
int getReduHost(string &sHost, int &iLevel, bool bActive)
{
int      iHostNum;
string   sDp;
bool     bStatus;
int      iLevel1, iLevel2;

  iHostNum = initHosts();
  if(iHostNum<0 || iHostNum>2)
    return(-1);

  sDp = "_ReduManager" + ((iHostNum==2) ? "_2" : "");
  dpGet(sDp+".MyErrorStatus:_online.._value",   iLevel1,
        sDp+".PeerErrorStatus:_online.._value", iLevel2,
        sDp+".EvStatus:_online.._value",        bStatus);

  sHost= (bStatus==bActive^iHostNum==2) ? host1 : host2;
  iLevel= (sHost==host1) ? iLevel1 : iLevel2;
  return(0);
}


//=============================================================================
// Get WAP-Group and all WAP-Groups and form links
//=============================================================================
// Dirk Hegewisch   07.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
void http_wapGroups(string &wml)
{
int i;
string          sGroup;      // Group-DP
dyn_string      asGroups;    // List of group-DPs
langString      lsGroup;     // Group-name
dyn_langString  alsGroups;   // List of group-names
dyn_string      asTypeFilter, asDpeFilter;

  // Get WAP-Group
  sGroup= groupNameToDpName(http_getConfig("wapGroup"));
  if(sGroup!="")
  {
    lsGroup= groupDpNameToName(sGroup);
    dynAppend(asGroups,  sGroup);
    dynAppend(alsGroups, lsGroup);
  }
  // Get list of WAP-Groups
  sGroup= groupNameToDpName(http_getConfig("wapGroupList"));
  if(sGroup!="")
  {
    groupGetFilterItems(sGroup, asTypeFilter, asDpeFilter);
    for(i=1; i<=dynlen(asTypeFilter); i++)
    {
      // if we have an group
      if(asTypeFilter[i]!="" && asDpeFilter[i]=="")
      {
        sGroup= asTypeFilter[i];
        lsGroup= groupDpNameToName(sGroup);
        dynAppend(asGroups,  sGroup);
        dynAppend(alsGroups, lsGroup);
      }
    }
  }

  // Make link-list of groups
  for(i=1; i<=dynlen(asGroups); i++)
  {
    wml += "<a href=\"/DPE_WAP?dpe=" + dpSubStr(asGroups[i], DPSUB_DP) + "\">";
    wml += alsGroups[i][$LangId] + "</a><br/>\n";
  }
}


//=============================================================================
// Get recent dpe-list
//=============================================================================
// Dirk Hegewisch   07.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_getRecentDpe(dyn_string &asList)
{
string s;

  html_load(s, "temp/dpeList.txt", "");
  asList= strsplit(s, "\n");
}
//=============================================================================
// Set recent dpe-list
//=============================================================================
// Dirk Hegewisch   07.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_setRecentDpe(dyn_string asList)
{
int    i;
string s;

  for(i=1; i<=dynlen(asList); i++)
    s += asList[i]+"\n";
  s= substr(s, 0, strlen(s)-1);
  html_save(s, "temp/dpeList.txt", "");
}
//=============================================================================
// Append recent dpe to list
//=============================================================================
// Dirk Hegewisch   07.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
http_appendRecentDpe(string sDpe)
{
int    iMax=  10;
int    iPos;
string s;
dyn_string asList;

  http_getRecentDpe(asList);
  iPos= dynContains(asList, sDpe);
  if(iPos>0)
    dynRemove(asList, iPos);
  else if(dynlen(asList)>=iMax)
    dynRemove(asList, iMax);
  dynInsertAt(asList, sDpe, 1);
  http_setRecentDpe(asList);
}
//=============================================================================
// Make optionlist for recent DPEs
//=============================================================================
// Dirk Hegewisch   07.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
void http_getRecentDpeOptions(string &sOptions)
{
int    i;
string s;
dyn_string asList;

  http_getRecentDpe(asList);
  for(i=1; i<=dynlen(asList); i++)
    sOptions +=  "<option value=\"" + asList[i] + "\">" + asList[i] + "</option>\n";
}


//=============================================================================
// Get string from size of given file
//=============================================================================
// Dirk Hegewisch   22.06.01
//
// Parameter:
//       sFile :  string   Filename (with Path)
//  Ret. value :  string   Size of given file
//
// Sample:
// string s;
//    s= getFileSizeString("C:\TEMP\PVS1.tmp");
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string getFileSizeString(string sFile)
{
int iFileSize;

  // Get size of file (return "" on error)
  iFileSize= getFileSize(sFile);
  if(iFileSize<0)  return("");

  // Return string of byte-size
  return(byteSizeToString(iFileSize));
}


//==============================================================================
// In this script (http.ctl) are all base functions for the PVSS-HTTP-server
// included.
//
// Dirk Hegewisch 15.01.01
//==============================================================================
//
// Included functions:
// -------------------
//  - Alert screen + some filter options
//  - Event screen + some filter options
//  - Datapoint elements / View all
//    informations of a DPE (and his configs)
//  - Interpreter for HTML-references
//    to make an dynamic HTML-Site.
//
//==============================================================================
// Changes: [15.03.01]-[MH]:[TI 9168: Subdir http unter Linux wird nicht angelegt]
// Changes: [06.03.01]-[DH]:[TI#9043: All files moved under 'data/http/']
// Changes: [01.06.01]-[DH]:[WAP (new Feature)]
// Changes: [Date]-[Name]:[Changes]
//==============================================================================

//=============================================================================
// Initalisize of the HTTP-server and CallBack-functions
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [15.03.01]-[MH]:[TI 9168: Subdir http unter Linux wird nicht angelegt] (mkdir "-p" eingef�gt)
// Changes: [06.03.01]-[DH]:[TI#9040: Create http-paths added]
// Changes: [26.04.01]-[DH]:[TI#9326: Cancel when no license]
// Changes: [30.04.01]-[DH]:[TI#9402: Insert HTML-References (new Feature)]
// Changes: [01.06.01]-[DH]:[WAP (new Feature)]
// Changes: [05.02.02]-[DH]:[TI#12910: Create all needed http-paths]
// Changes: [11.02.02]-[DH]:[TI#13994: Get HTTP-Server Portnumber from Configentry]
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// dyn_string additionalConfigFileNames ... Liste aller zus�tzlich einzulesender
//                                HTTP-config files. Als erster wird IMMER der
//                                Default-config-file eingelesen.
//------------------------------------------------------------------------------
void HttpMain(dyn_string additionalConfigFileNames)
{
  int  iErr;
  dyn_string configFileNames;
  http_setGlobals();
  http_makePathes();

  configFileNames = makeDynString("config.http");

  // setTrace(VERIFY_TRACE);
  // Load configfile - Init configs
  dynAppend(configFileNames, additionalConfigFileNames);
  http_initConfig(configFileNames);

  // Start the HTTP-server

  iErr= httpServer(http_getConfig("httpLogin")=="pvss",
                   http_getConfig("httpServerPort"),
                   http_getConfig("httpsPort"));
  if(0 <= iErr)
  {
    if ( httpCheckDebug() ) DebugN("===> HTTP-Server started at port:",http_getConfig("httpServerPort"));
  }
  else
  {
    int httpsPort;
    string httpsError;

    httpsPort=http_getConfig("httpsPort");
    if ( httpsPort != 0 )
      httpsError = " - SSL/https: - initialisation problem (port: "+  httpsPort + ")\n";

    // Cancel when no license
    DebugN("ERROR: HTTP-server can't start. Reasons:\n"+
           " - Portnumber " + http_getConfig("httpServerPort") + " is allready in use\n"+
           httpsError +
           " - No license available");
    return;
  }

  http_Connects();
  // setTrace(NO_TRACE);
}


//=============================================================================
// statisches Flag
int httpCheckDebugFlag = 0;

//=============================================================================
// Wolfram Klebel, 20.10.03
// Erlaubt das Schalten von benannte Debug-Flags �ber
//=============================================================================
int httpCheckDebug( int level = 4 )
{

  if (httpCheckDebugFlag == 0)    // noch nicht initialisiert
  {
    if (isDbgFlag( "http1" ))
      httpCheckDebugFlag = 1;
    else if (isDbgFlag( "http2" ))
      httpCheckDebugFlag = 2;
    else if (isDbgFlag( "http3" ))
      httpCheckDebugFlag = 3;
    else if (isDbgFlag( "http4" ))
      httpCheckDebugFlag = 4;
    else
      httpCheckDebugFlag = -1;

    if ( httpCheckDebugFlag > 0)
      DebugN( "INFO: switching ON Debugs for HTTP set to " + httpCheckDebugFlag );
  }

  return( httpCheckDebugFlag >= level );
}
//=============================================================================
// Initializise config parameter and values form HTTP config-file
//=============================================================================
// Dirk Hegewisch   16.02.01
//
// Changes: [15.03.01]-[MH]:[TI 9168: Subdir http unter Linux wird nicht angelegt] (Abfangen sFilename == "")
// Changes: [06.03.01]-[DH]:[TI#9044: Changed default email and logo-links]
// Changes: [11.02.02]-[DH]:[TI#13994: New entry HTTP-Server Portnumber]
//------------------------------------------------------------------------------
void http_initConfig(dyn_string configFileNames)
{
int        i, iPos, iCount, level;
string     s;
dyn_string as;
string     sFilename;    // Config file-name
file       configFile;
string     sLine;        // Line of config-file
string     sParameter;   // config-parameter
string     sValue;       // config-value
string     sStyleName;   // Style-sheet name
string     sStyleCode;   // Style-sheet code
string     configFileName;
bool       configFound;

  // Set default parameter values
  http_setConfig("httpServerPort",          "80");

  if (_WIN32)
    http_setConfig("httpsPort",        "0"); // deactivate by default on WIN32 (IM 61670)!
  else
    http_setConfig("httpsPort",      "443"); // activate by default on Linux !

  http_setConfig("httpLogin",               "pvss");
  http_setConfig("httpAccesscode",          "");
  http_setConfig("httpMainTitle",           "WinCC OA HTTP-Server Yinls");
   s= PROJ_PATH;
   strreplace(s, "\\", "/");
   as= strsplit(s, "/");
   s= as[dynlen(as)];
  http_setConfig("httpSubTitle",            "Project: '"+s+"'");
  http_setConfig("wapTitle",                s);
   s= getHostname();
  http_setConfig("httpWelcomeText",         "Willkommen beim WinCC OA HTTP-Server ["+s+"]<br>Welcome to the WinCC OA HTTP-Server<br><br>"+
                                            "Bitte klicken Sie auf eine der Flaggen, um eine Sprache auszuw�hlen<br>"+
                                            "Please click on one of the flags to select a language");
  http_setConfig("wapTitleURL",             "wap.pvss.com");
  http_setConfig("wapInfoText",             "Welcome to<br/>WinCC OA WAP<br/>Email:<br/><b>product_center@etm.at</b>");
  http_setConfig("wapLanguage",             "");
  http_setConfig("wapRedirectionDelay",     "10");
  http_setConfig("wapGroup",                "WAP-Group");
  http_setConfig("wapGroupList",            "WAP-Datasets");
  http_setConfig("httpCopyRightText",       "Copyright 2003-2007 ETM professional control GmbH");
  http_setConfig("httpBackColorLight",      "#88bbee");
  http_setConfig("httpFontColorLight",      "#000000");
  http_setConfig("httpBackColorDark",       "#6699cc");
  http_setConfig("httpFontColorDark",       "#ffffff");
  http_setConfig("httpBackColorAnswer",     "#c0c0c0");
  http_setConfig("httpFontColorAnswer",     "#000000");
  http_setConfig("httpFontFamily",          "arial");
  http_setConfig("httpStartPageLogoLink",   "http://www.etm.at/");
  http_setConfig("httpHeaderLogoLeftLink",  "http://www.pvss.com/");
  http_setConfig("httpHeaderLogoRightLink", "http://www.etm.at/");
  http_setConfig("httpHomeLink",            "main.html");
  http_setConfig("httpHelpLink",            "WebHelp/HTTP_Server/http1-02.htm");
  http_setConfig("httpMailTo",              "product_center@etm.at");
  http_setConfig("httpLastChanges",         "11.10.2007");

  // Search for config-file in all (sub-)projects:
  configFound=FALSE;

  for ( i=1; i<=dynlen(configFileNames); i++ )
  {
    configFileName=configFileNames[i];
    if (strlen( configFileName ) <= 0 ) // keine Leereintraege ...
      continue;

    if ( httpCheckDebug() ) DebugN(" ... searching for config file <" + configFileName + ">");

    for ( level=SEARCH_PATH_LEN; level > 0 ; level-- )
    {
      sFilename= getPath(CONFIG_REL_PATH, configFileName, -1, level);

      strreplace(sFilename, "\\", "/");
      strreplace(sFilename, "//", "/");

      // Open config-file
      if(( access( sFilename, F_OK )) || (strlen( sFilename ) <= 0 ))
        continue;

      configFile= fopen(sFilename, "r");
      if (ferror(configFile)) // If no config-file exists
        continue;               // return

      configFound=TRUE;

      // Read config-file
      if ( httpCheckDebug() ) DebugN("- Reading HTTP config-file -" + sFilename );
      while(fgets(sLine, 8192, configFile)>0)
      {
        // Cut spaces left and right
        sLine = strltrim(strrtrim(sLine));
        //DebugN(" ... reading line: " + sLine );

        // if no comment-line
        if( sLine[0]!='#' )
        {
          // get parameter
          iCount= sscanf(sLine, "%s %s",
            sParameter, s);
          if( strltrim(strrtrim(s))=='=' && iCount==2 )
          {
            // get value
            iPos= (strpos(sLine, "\"") );  //"
            if(iPos<0)
            {
              DebugN("HTTP-Error: Missing '' for parameter '"+sParameter+"' !");
              fclose(configFile);
              return;
            }
            sLine=  substr(sLine, iPos+1, strlen(sLine)-(iPos+1) );
            iPos= (strpos(sLine, "\"") );  //"
            if(iPos<0)
            {
              DebugN("HTTP-Error: Missing '' for parameter '"+sParameter+"' !");
              fclose(configFile);
              return;
            }
            sValue= substr(sLine, 0, iPos );
            // Check for PVSS-color
            if(strpos(sParameter, "Color")>0 && sValue[0]!='#')
            {
              http_getColorNameFromColorDB(sValue, s);
              if(s[0]=='#')  sValue= s;
            }
            // set paramter and value into config-list
            if ( httpCheckDebug() )
            {
              DebugN("http_setConfig: sParameter=", sParameter);
              DebugN("http_setConfig: sValue=",sValue);
            }
            http_setConfig(sParameter, sValue);
          }
        } // off comment
      } // off while
      fclose(configFile);
    }
  }

  if (!configFound)
    return;  // kein einziger gefunden ...

  // Check for style-sheet files
  for(i=1; i<=dynlen(gasConfigParameter); i++)
  {
    if( strpos(gasConfigParameter[i], "httpBackColor")==0 )
    {
      // Get style-sheet name
      sStyleName= gasConfigParameter[i];
      strreplace(sStyleName, "httpBackColor", "");
      sFilename= "style/"+dcase(sStyleName)+".css";
      // Make style-sheet
      sStyleCode= "body{background-color:" + http_getConfig("httpBackColor"+sStyleName) + ";\n" +
                  "  color:"               + http_getConfig("httpFontColor"+sStyleName) + ";\n" +
                  "  font-family:\""       + http_getConfig("httpFontFamily") + "\";}\n" +
                  "p{color:"               + http_getConfig("httpFontColor"+sStyleName) + ";\n" +
                  "  font-family:\""       + http_getConfig("httpFontFamily") + "\";}\n" ;
      // Save style-sheet
      html_save(sStyleCode, sFilename, "");
    }
  } // of for config-parameters
}


//=============================================================================
// Set or replace an value for given parameter-name in global config-list
//=============================================================================
// Dirk Hegewisch   16.02.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
void http_setConfig(string sParameter, string sValue)
{
int iPos;
  // Set value to config-list
  iPos= dynContains(gasConfigParameter, sParameter);
  if(iPos<1)  iPos= dynlen(gasConfigParameter)+1;
  gasConfigParameter[iPos]= sParameter;
  gasConfigValue[iPos]=     sValue;
}


//=============================================================================
// Callback-Funktion to get an HTML-table out of an PVSS query-result
//=============================================================================
// Dirk Hegewisch   31.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string queryCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int    i, iPos, iErr;
string html;            // Html answer site
string htmlBase;        // HTML-base site
string sBaseFile;       // HTML-base file
string sResultFile;     // HTML-result file
string sQuery;          // Query-string
dyn_dyn_anytype  tab;   // Query result
bool   bHead;           // Make table head
int    iLines= 100;     // Max. lines each Page
string sInfo;           // Info-text

  // Get parameters
  iPos= dynContains(asParameter, "file");
  if(iPos>0)  sBaseFile= asValue[iPos];
  iPos= dynContains(asParameter, "query");
  if(iPos>0)  sQuery= asValue[iPos];
  iPos= dynContains(asParameter, "head");
  if(iPos>0)  bHead= asValue[iPos];
  iPos= dynContains(asParameter, "lines");
  if(iPos>0)  iLines= asValue[iPos];

  // Check if all needed parameters exists
  if(sBaseFile=="" || sQuery=="")
  {
    if(sBaseFile=="")
      sprintf(sInfo,  getCatStr("http", "paraMissing", http_getLangId(sIP)), "file");
    if(sQuery=="")
      sprintf(sInfo,  getCatStr("http", "paraMissing", http_getLangId(sIP)), "query");
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    return(html);
  }

  // Load html table-base
  iErr= html_load(htmlBase, sBaseFile, sIP);
  // if loading fails
  if(iErr<0)
  {
    sprintf(sInfo,  getCatStr("http", "errFileLoad", http_getLangId(sIP)), sBaseFile);
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    return(html);
  }

  // Do the query
  iErr= dpQuery(sQuery, tab);
  // Error in query-string
  if(iErr<0)
  {
    sprintf(sInfo,  getCatStr("http", "errQuery", http_getLangId(sIP)), sQuery);
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    return(html);
  }

  // Check for table-head
  if(bHead)
  {
    html =  "<tr>\n";
    html += " <th>DPE</th>\n";
    for(i=2; i<=dynlen(tab[1]); i++)
      html += " <th>" + tab[1][i] + "</th>\n";
    html += "</tr>\n";
    strreplace(htmlBase, "#table", html+"#table");
  }
  // Remove query-head
  if(dynlen(tab)>0)  dynRemove(tab, 1);

  // Make result site(s)
  sResultFile= sBaseFile;
  strreplace(sResultFile, ".", "_%d.");
  html= html_makeTablePages(tab, iLines, sResultFile,
                            htmlBase, "query", sIP);
  return(html);
}


//=============================================================================
// Check Accesscode if 'code' is set in config-file
//=============================================================================
// Dirk Hegewisch   28.05.01
// Return:  1 -> Code is valid
//          0 -> No code given
//         -1 -> Wrong code
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
int http_checkAccessCode(string sCode, string sIP)
{
unsigned   uMAX_TIME= 5*60;  // 5 Min.
dyn_string asCode;

  if(http_getConfig("httpLogin") != "code")
  {
    http_setLoginTime(sIP);
    return(1);
  }
  // Check if 'old' login valid
  if(http_getLoginTime(sIP)+uMAX_TIME > getCurrentTime() )
  {
    http_setLoginTime(sIP);
    return(1);
  }
  if(sCode == "")
    return(0);
  // Check for valid code
  asCode= strsplit(http_getConfig("httpAccesscode"), ",");
  if(dynContains(asCode, sCode) > 0)
  {
    http_setLoginTime(sIP);
    return(1);
  }
  else
    return(-1);
}


//=============================================================================
// function to set language in start-site
//=============================================================================
// Wolfram Klebel 31.7.03
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_getChooseLangPanel( string startUrl, string sUser, string sIP )
{
  int i, iId, iErr;
  string html, htmlBase;
  string sFilename;
  string sLang, sImg, sSelect;

  sFilename= "start/chooseLang.html";
  // Insert config texts in start-site
  html_loadReference(sFilename, makeDynString("http_StartUrl"), makeDynString( startUrl ), "", "", iErr);
  // Load site and insert language-flags
  iErr= html_load(htmlBase, sFilename, "");
  html= "";
  html_tableRowStart(html);
  for (i=0; i<getNoOfLangs(); i++)
  {
    sLang= getLocale(i);
    sImg= "<a href=\"" + startUrl + "lang="+sLang+"\">"+
          "<img src=\"/pictures/http/flags/"+sLang+".gif\" border=\"0\">"+
          "</a>\n";
    sSelect= (sLang==http_getLangName(sIP)) ? "#000000" : "";
    html_tableCell(html, sImg, sSelect);
  }
  html_tableRowEnd(html);
  strreplace(htmlBase, "#table", html);
  sLang= http_getLangName(sIP);
  if(sLang=="")
  {
    iId= getActiveLang();
    sLang= getLocale(iId);
  }
  strreplace(htmlBase, "#lang", sLang);
  return(htmlBase);

}


//=============================================================================
// Callback-Funktion to set language in start-site
//=============================================================================
// Dirk Hegewisch   19.01.01
//
// Changes: [15.06.01]-[DH]:[TI#9968: Check if language-dir for http exists]
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string startCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iPos, iErr;
int     iId;      // Language-Id
string  sLang;    // PVSS language name
string  sLangName;// Language name
string  sLangDir; // Language dirctory
string  sImg;     // Contry flag image
string  sSelect;  // Mark choosen Flag
bool    bNew;     // Select new language
string  sCode;    // Login Accesscode
string  html, htmlBase;
string  sPath;    // Language Dir-Path
dyn_dyn_string tab;


  // Check access rights (code)
  iPos= dynContains(asParameter, "code");
  if(iPos>0)  sCode= asValue[iPos];
  iErr= http_checkAccessCode(sCode, sIP);
  if( iErr <= 0 )
  {
    string sFilename;
    sFilename= (iErr==0) ? "start/getAccessCode.html" : "start/wrongAccessCode.html";
    html_load(html, sFilename, "");
    return(html);
  }

  // Check for new choosen language
  iPos= dynContains(asParameter, "lang");
  if(iPos>0)  sLang= asValue[iPos];
  iPos= dynContains(asParameter, "new");
  if(iPos>0)  bNew= asValue[iPos];

  // No language selected or wish to select new one
  if(sLang=="" || bNew)
  {
    sLang= http_getLangName(sIP);
    if(sLang=="" || bNew)  // no Lang selected
    {
      return( http_getChooseLangPanel( "/?", sUser, sIP ));
    }
  }
  // Give a site to select language
  else
  {
    if (http_setLangByName( sIP, sLang ) == -1)
    {
      html= html_forwardRef("start/noLang.html&lang=" + sLang + "&langDir=" + http_getLangDir( sIP ), 0, "");
      return(html);
    }
  }

  // Forward to selected Language
  html= html_forwardRef("index.html", 0, sIP);
  return(html);
}
//=============================================================================
// WAP! Callback-Funktion to set language in start-site
//=============================================================================
// Dirk Hegewisch   28.05.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string startWapCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iPos, iErr;
int     iId;      // Language-Id
string  sLang;    // PVSS language name
string  sLangName;// Language name
string  sLangDir; // Language dirctory
string  sImg;     // Contry flag image
string  sSelect;  // Mark choosen Flag
bool    bNew;     // Select new language
string  sCode;    // Login Accesscode
string  html, htmlBase;
dyn_dyn_string tab;

  // Check access rights (code)
  iPos= dynContains(asParameter, "code");
  if(iPos>0)  sCode= asValue[iPos];
  iErr= http_checkAccessCode(sCode, sIP);
  if( iErr <= 0 )
  {
  string sFilename;
    sFilename= (iErr==0) ? "start/getAccessCode.wml" : "start/wrongAccessCode.wml";
    html_load(html, sFilename, "");
    return(html);
  }

  // Check for new choosen language
  iPos= dynContains(asParameter, "lang");
  if(iPos>0)  sLang= asValue[iPos];
  iPos= dynContains(asParameter, "new");
  if(iPos>0)  bNew= asValue[iPos];

  // Check WAP
  iPos= dynContains(asParameter, "wap");
  if(iPos>0)  bWap= asValue[iPos];

  // Set language and load WAP start site
  if(sLang!="")
  {
    http_setLangByName( sIP, sLang );

    // Go to main menu
    html_loadReference("index.wml", makeDynString(), makeDynString(), sIP, sUser, iErr);
    html_load(html, "index.wml", sIP);
    return(html);
  }
  else if(bNew)
  {
    // Choose language
    wml_start(html, "Language ?", "lang", "");
    for (i=0; i<getNoOfLangs(); i++)
    {
      sLang= getLocale(i);
      sLangName= substr(sLang, 0, 2);
      switch(sLangName)
      {
        case "de":  sLangName= "German";  break;
        case "en":  sLangName= "English";  break;
        case "hu":  sLangName= "Hungarian";  break;
        case "jp":  sLangName= "Japanese";  break;
        case "zh":  sLangName= "Chinese";  break;
        case "nl":  sLangName= "Dutch";  break;
        case "tr":  sLangName= "Turkish";  break;
        case "it":  sLangName= "Italian";  break;
        case "fr":  sLangName= "French";  break;
        case "es":  sLangName= "Spanish";  break;
        case "el":  sLangName= "Greek";  break;
        case "iw":  sLangName= "Hebrew";  break;
        case "da":  sLangName= "Danish";  break;
        case "fi":  sLangName= "Finnish";  break;
        case "no":  sLangName= "Norwegian";  break;
        case "pt":  sLangName= "Portuguese";  break;
        case "sv":  sLangName= "Swedish";  break;
        case "is":  sLangName= "Icelandic";  break;
        case "cs":  sLangName= "Czech";  break;
        case "pl":  sLangName= "Polish";  break;
        case "ro":  sLangName= "Rumanian";  break;
        case "hr":  sLangName= "Croatian";  break;
        case "sk":  sLangName= "Slovakian";  break;
        case "sl":  sLangName= "Slovenian";  break;
        case "ru":  sLangName= "Russian";  break;
        case "bg":  sLangName= "Bulgarian";  break;
        case "ar":  sLangName= "Arabic";  break;
        case "ko":  sLangName= "Korean";  break;
        case "ja":  sLangName= "Japanese";  break;
        case "th":  sLangName= "Thai";  break;
        default:
          DebugN("unknown language '"+sLang+"'");
      }
      if(sLang == http_getLangName(sIP))
        sLangName= "&gt;" + sLangName + "&lt;";
      html += "<a href=\"/wap?lang=" + sLang + "\">" +
              sLangName + "</a><br/>\n";
    }
    wml_end(html);
    return(html);
  }
  // Modify start-site-link and forward time
  html_load(html, "start/wap.wml", "");
  if(sLang=="")  sLang= http_getLangName(sIP);
  if(sLang=="")  sLang= http_getConfig("wapLanguage");
  if(sLang!="")
    strreplace(html, "#call", "lang="+sLang);
  else
    strreplace(html, "#call", "new=1");
  strreplace(html, "#url",    http_getConfig("wapTitleURL"));
  strreplace(html, "#time",   http_getConfig("wapRedirectionDelay"));
  return(html);
}


//=============================================================================
// Callback-Funktion for HTTP-Help  [16.07.01]-[DH]:[TI#9096]
//=============================================================================
// Dirk Hegewisch   25.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string helpCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int iErr;
string  sPath, sFilename;
string  html;

  sFilename=  http_getConfig("httpHelpLink");
  sPath= getPath(HELP_REL_PATH, sFilename,  http_getLangId(sIP));

  if(sPath!="")  // Go to Help-Site
  {
    sFilename= substr(sPath, strpos(sPath, "help")-1);
    strreplace(sFilename, "\\", "/");
    html= "<HTML><HEAD>\n"+
          "<meta http-equiv='refresh' content='0; "+
          "URL=" + sFilename + "'>\n"+
          "</HEAD></HTML>";
  }
  else  // No help founded
  {
  string sInfo;
    sFilename= "/help/" + http_getLangName(sIP) + "/" + sFilename;
    sprintf(sInfo,  getCatStr("http", "noHelp", http_getLangId(sIP)), sFilename);
    html_info(html, getCatStr("http", "info", http_getLangId(sIP)), sInfo);
  }
  return(html);
}

//=============================================================================
// Get Alertscreen-table (and Save/Load properties)
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string alertsCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iErr, iPos;
time    t1, t2;         // Start and end-time
string  sT1, sT2;       // Start and end-time
string  sFilter;        // DP-Filter
string  sAction;        // Action (get-table/load-props/save-props)
int     iMaxLines;      // Maximum tablelines for each page
string  query;          // Querystring
string  from, where;    // Query-states FROM/WHERE
string  html, htmlBase; // HTML answer
string  sFile;          // Filename for properties
dyn_dyn_anytype tab, sortedtab;   // Query-Result
dyn_dyn_string  rettab;           // Table-Lines
dyn_string  valDpList;            // DP-Filter-Liste
int         valType;              // At this Moment=1 / Closed=2
int         valState;             // Alert-State
string      valPrio= "0-9999";    // Alert-Priority
bool        valTypeAlertSummary= true;
string      valShortcut;
string      valAlertText;
dyn_int     valTypeSelections;
int         row, col, pos;

//DebugN("***Aufruf von alertCB***",sIP);
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  t1= getTimeFromParameter("t1", asParameter, asValue);
  t2= getTimeFromParameter("t2", asParameter, asValue);
  sT1= t1;
  sT2= t2;
  if(t2<t1)
  {
    html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                    getCatStr("http", "timeEndStart", http_getLangId(sIP)) );
    return(html);
  }
  iPos= dynContains(asParameter, "filter");
  if(iPos>0) sFilter= asValue[iPos];
  strreplace(sFilter, "\r", "");
  valDpList = strsplit(sFilter, "\n");
  iPos= dynContains(asParameter, "alertState");
  if(iPos>0)  valState= asValue[iPos];
  iPos= dynContains(asParameter, "timeRange");
  if(iPos>0)  valType= asValue[iPos];
  // Maximum Lines in ResultPage
  iPos= dynContains(asParameter, "maxLines");
  if(iPos>0)  iMaxLines= asValue[iPos];
  else        iMaxLines= 25;

  // Look what action is called
  if(dynContains(asParameter, "load.x") >0 )       sAction= "load";
  else if(dynContains(asParameter, "save.x") >0 )  sAction= "save";
  else                                             sAction= "get";

  // Save or load properties
  if(sAction=="load" || sAction=="save")
  {
    sFile= sIP;
    strreplace(sFile, ".", "");
    sFile= "as/load_"+sFile+".html";
    if(sAction=="load")
    {
      iErr= html_load(html, sFile, sIP);
      if(iErr<0)
        html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                        getCatStr("http", "loadError", http_getLangId(sIP)) );
    }
    else
    {
    string sJava;  // Java Script

      // Build loadsite with parameter
      strreplace(sFilter, "\n", "\\n");
      iMaxLines= dynContains(makeDynInt(10,20,50,100), iMaxLines);
      sJava += "<script language=\"JavaScript\">\n";
      sJava += " parent.props.document.Prop.filter.value = \""+sFilter+"\";\n";
      sJava += " parent.props.document.Prop.maxLines["+(iMaxLines-1)+"].selected=true;\n";
      sJava += " parent.props.document.Prop.timeRange["+(valType-1)+"].checked=true;\n";
      sJava += " parent.props.change(parent.props.Prop,"+ ( (valType==1)?"true":"false" )+ ");\n";
      sJava += " parent.props.document.Prop.alertState["+valState+"].checked=true;\n";
      sJava += "</script>\n";
      html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                      getCatStr("http", "propsLoaded", http_getLangId(sIP)) );
      strreplace(html, "</title>", "</title>\n"+sJava );
      iErr= html_save(html, sFile, sIP);

      if(iErr>=0)
        html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                        getCatStr("http", "propsSaved", http_getLangId(sIP)) );
      else
        html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                        getCatStr("http", "saveError", http_getLangId(sIP)) );
    }
    return(html);
  }

  // *** Get Alert-table ***
  // Form the alert query-string
  as_getFromWhere(from, where,
                  valState, valShortcut, valPrio, valAlertText,
                  valDpList, valTypeSelections, valTypeAlertSummary, valType);
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state'";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM "+from;
  query += " WHERE ('_alert_hdl.._prior' >= 0)"+where;
  if(valType==2)
    query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
//DebugN("Query:",query);

  dpQuery(query,tab);
//DebugN("<<<tab>>>",tab);

  // Sort and convert the query-result
  sortedtab = sortTab(tab);
  rettab = convertAlertTab(sortedtab, sIP);
//DebugN("<<<rettab>>>",rettab);

  // Load html table-base
  iErr= html_load(htmlBase, "as/as_result.html", sIP);
  html_delete("as/result/page_"+gcAsFileRing+"*.html", sIP);
  html= html_makeTablePages(rettab, iMaxLines, "as/result/page_"+gcAsFileRing+"%d.html",
                            htmlBase, "as", sIP);
  gcAsFileRing ++;
  if(gcAsFileRing>'j')  gcAsFileRing= 'a';
  return(html);
}
//=============================================================================
// WAP Alertscreen
//=============================================================================
// Dirk Hegewisch   29.05.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string alertsWapCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iErr, iPos;
time    t1, t2;         // Start and end-time
string  sT1, sT2;       // Start and end-time
int     iView;          // View alerts
string  query;          // Querystring
string  from, where;    // Query-states FROM/WHERE
string  wml, wmlBase;       // WML answer
int     iPendingAlerts;     // Number of pending alerts
int     iUnackPendAlerts;   // Number of unack&pending alerts
int     iLastAlerts;        // Number alerts in last hour
dyn_dyn_anytype tab, sortedtab;   // Query-Result
dyn_dyn_string  rettab;           // Table-Lines
dyn_string  valDpList;            // DP-Filter-Liste
int         valType;              // At this Moment=1 / Closed=2
int         valState;             // Alert-State
string      valPrio= "0-9999";    // Alert-Priority
bool        valTypeAlertSummary= true;
string      valShortcut;
string      valAlertText;
dyn_int     valTypeSelections;
int         row, col, pos;

//DebugN("***Aufruf von alertWapCB***",sIP);
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  iPos= dynContains(asParameter, "view");
  if(iPos>0) iView= asValue[iPos];


  // *** Get Alert-table ***
  valType   = 1;  // actual
  valDpList = makeDynString();
  valState  = 2;  // pending
  // Form the alert query-string
  as_getFromWhere(from, where,
                  valState, valShortcut, valPrio, valAlertText,
                  valDpList, valTypeSelections, valTypeAlertSummary, valType);
  query = "SELECT ALERT ";
  query += "'_alert_hdl.._abbr','_alert_hdl.._prior','_alert_hdl.._text'";
  query += ",'_alert_hdl.._direction','_alert_hdl.._value','_alert_hdl.._ack_state'";
  query += ",'_alert_hdl.._visible','_alert_hdl.._alert_color','_alert_hdl.._ackable'";
  query += ",'_alert_hdl.._ack_oblig','_alert_hdl.._oldest_ack'";
  query += " FROM "+from;
  query += " WHERE ('_alert_hdl.._prior' >= 0)"+where;
  dpQuery(query,tab);

  // Show all pending alerts
  if(iView>0)
  {
    // Sort and convert the query-result
    sortedtab = sortTab(tab);
    rettab = convertAlertTab(sortedtab, sIP);
    // Load wml base-card
    iErr= html_load(wmlBase, "as/as_result.wml", sIP);
    html_delete("as/result/page_"+gcAsFileRing+"*.wml", sIP);
    // Create result WML-Decks
    wml= wml_makeResultDecks(rettab, 3, "as/result/page_"+gcAsFileRing+"%d.wml",
                             wmlBase, "as", sIP);
    gcAsFileRing ++;
    if(gcAsFileRing>'j')  gcAsFileRing= 'a';
  }
  // Alert statistik-overview (Number of Alerts)
  else
  {
    // Count pending alerts
    dynRemove(tab,1);
    iPendingAlerts= dynlen(tab);
    // Count unack&pending alerts
    for(i=1; i<=iPendingAlerts; i++)
      if(tab[i][11])  iUnackPendAlerts++;

    // Get alerts of last hour
    valType   = 2;  // closed
    valDpList = makeDynString();
    valState  = 0;  // all
    valTypeAlertSummary = false;
    t2= getCurrentTime();
    t1= t2-3600;
    sT1= t1;
    sT2= t2;
    // Form the alert query-string
    as_getFromWhere(from, where,
                    valState, valShortcut, valPrio, valAlertText,
                    valDpList, valTypeSelections, valTypeAlertSummary, valType);
    query = "SELECT ALERT ";
    query += "'_alert_hdl.._direction'";
    query += " FROM "+from;
    query += " WHERE ('_alert_hdl.._prior' >= 0)";
    query += " AND ('_alert_hdl.._direction' == 1)";
    query += where;
    if(valType==2)
      query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";
    dpQuery(query,tab);
    iLastAlerts= dynlen(tab)-1;

    wml_start(wml, getCatStr("http", "alerts", http_getLangId(sIP)), "alerts", "");
    wml += getCatStr("http", "pending",    http_getLangId(sIP)) + ":<b> " + iPendingAlerts   + "</b><br/>\n";
    wml += getCatStr("http", "unackPend",  http_getLangId(sIP)) + ":<b> " + iUnackPendAlerts + "</b><br/>\n";
    wml += getCatStr("http", "lastAlerts", http_getLangId(sIP)) + ":<b> " + iLastAlerts      + "</b><br/>\n";
    wml += "<a href=\"/AlertWap?view=1\">";
    wml += getCatStr("http", "alertDisplay", http_getLangId(sIP)) + "</a><br/>\n";
    wml += "<a href=\"/data/http/" + substr(http_getLangName(sIP), 0, 2) + "/index.wml\">";
    wml += getCatStr("http", "mainMenu", http_getLangId(sIP)) + "</a><br/>\n";
    strreplace(wml, "<wml>",
               "<wml>\n<template>"+
               "<do type=\"prev\" label=\""+ getCatStr("http", "back", http_getLangId(sIP)) +"\"><prev/></do>\n"+
               "<do type=\"go\" label=\""+ getCatStr("http", "alerts", http_getLangId(sIP)) +"\"><go href=\"/AlertWap?view=1\"/></do>"+
               "</template>");
    wml_end(wml);
  }

  // Return WML-Code
  return(wml);
}


//=============================================================================
// Get historical event-table (and Save/Load properties)
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string eventsCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iErr, iPos;
time    t1, t2;         // Start and end-time
string  sT1, sT2;       // Start and end-time
string  sFilter;        // DP-Filter
string  sAction;        // Action (get-table/load-props/save-props)
int     iMaxLines;      // Maximum tablelines for each page
string  html, htmlBase; // HTML answer
string  sFile;          // Filename for properties
dyn_dyn_anytype ret, tab;
string  query;          // Querystring
string  from, where;    // Query-states FROM/WHERE
string  valdpComment;
dyn_string valDpList;
bit32   valUserbits;
dyn_int valTypeSelection;

//DebugN("***Aufruf von eventCB***");
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  t1= getTimeFromParameter("t1", asParameter, asValue);
  t2= getTimeFromParameter("t2", asParameter, asValue);
  sT1= t1;
  sT2= t2;
  if(t2<t1)
  {
    html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                    getCatStr("http", "timeEndStart", http_getLangId(sIP)) );
    return(html);
  }
  iPos= dynContains(asParameter, "filter");
  if(iPos>0)  sFilter= asValue[iPos];
  strreplace(sFilter, "\r", "");
  valDpList = strsplit(sFilter, "\n");
  // Maximum Lines in ResultPage
  iPos= dynContains(asParameter, "maxLines");
  if(iPos>0)  iMaxLines= asValue[iPos];
  else        iMaxLines= 25;

  // Look what action is called
  if(dynContains(asParameter, "load.x") >0 )       sAction= "load";
  else if(dynContains(asParameter, "save.x") >0 )  sAction= "save";
  else                                             sAction= "get";

  // Save or load properties
  if(sAction=="load" || sAction=="save")
  {
    sFile= sIP;
    strreplace(sFile, ".", "");
    sFile= "es/load_"+sFile+".html";
    if(sAction=="load")
    {
      iErr= html_load(html, sFile, sIP);
      if(iErr<0)
        html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                        getCatStr("http", "loadError", http_getLangId(sIP)) );
    }
    else
    {
    string sJava;  // Java Script

      // Build loadsite with parameter
      strreplace(sFilter, "\n", "\\n");
      iMaxLines= dynContains(makeDynInt(10,20,50,100), iMaxLines);
      sJava += "<script language=\"JavaScript\">\n";
      sJava += " parent.props.document.Prop.filter.value = \""+sFilter+"\";\n";
      sJava += " parent.props.document.Prop.maxLines["+(iMaxLines-1)+"].selected=true;\n";
      sJava += "</script>\n";
      html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                      getCatStr("http", "propsLoaded", http_getLangId(sIP)) );
      strreplace(html, "</title>", "</title>\n"+sJava );
      iErr= html_save(html, sFile, sIP);

      if(iErr>=0)
        html_info(html, getCatStr("http", "info", http_getLangId(sIP)),
                        getCatStr("http", "propsSaved", http_getLangId(sIP)) );
      else
        html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                        getCatStr("http", "saveError", http_getLangId(sIP)) );
    }
    return(html);
  }

  // *** Get historical event-table ***
  // Form the event query-string
  es_getFromWhere(from, where, valDpList, valUserbits, valdpComment, valTypeSelection, false);
  query =  "SELECT ";
  query += "'_offline.._stime', '_offline.._value', '_offline.._status', '_offline.._text'";
  query += " FROM "+ from;
  query += " WHERE  _LEAF " + where;
  query += " TIMERANGE(\"" + sT1 + "\",\"" + sT2 + "\",1,0)";

  dpQuery(query, ret);

  // Convert the query-result
  tab = convertEventTab(ret, sIP);

  // Load html table-base
  iErr= html_load(htmlBase, "es/es_result.html", sIP);
  html_delete("es/result/page_"+gcEsFileRing+"*.html", sIP);
  html= html_makeTablePages(tab, iMaxLines, "es/result/page_"+gcEsFileRing+"%d.html",
                            htmlBase, "es", sIP);
  gcEsFileRing ++;
  if(gcEsFileRing>'j')  gcEsFileRing= 'a';
  return(html);
}


//=============================================================================
// Make and save result table-pages
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function makes out of an given query-result automaticly one or
// or more HTML-sites. This sites where saved with names like given in
// sFileset.
// To bulid this site where used the given htmlBase-file,
// and the given 'key'-strings where replaced. The result is an HTML-Site.
//
// Parameter:
//         tab :  dyn_dyn_anytype  Field with table-values
//   iMaxLines :  int              Max. lines each HTML-Site
//    sFileset :  string           HTML file namen-set (%d for page-number)
//    htmlBase :  string           HTML base-site incl. table-head.
//                                 folowing 'key'-string where replaced:
//                    #tabel = Table row and colums
//                    #lines = Number of result pages
//                    #page  = Actual page number
//                    #pages = Number of total pages
//                    #next  = Navigation one site back/forward
//       sMode :  string           Special-mode / "as"=alert-screen
//  Ret. value :  string           HTML-Site the call the result table(s)
//
// Sample:
// string html;
//    html= html_makeTablePages(tab, 25, "result/page_%d.html", htmlBase);
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string html_makeTablePages(dyn_dyn_anytype &tab, int iMaxLines, string sFileset,
                           string htmlBase, string sMode, string sIP)
{
int     i, iErr;
string  html, htmlPages;     // Result pages
int     iPages;              // Number of pages
int     iLines;              // Number of result-lines
int     iStartRow, iEndRow;  // Start/end row
string  sFilename;           // Page-filename
string  sFilebase;           // Fileset without path
int     iRow, iCol;          // Row/col counter
string  sLink;               // Link for page-navigation
string  sInfo;

  // Get Filebase
  i= strlen(sFileset);
  while(i>0 && sFileset[i-1]!='/') i--;
  sFilebase= substr(sFileset, i, strlen(sFileset)-i);

  // Number of resultPages
  iLines= dynlen(tab);
  iPages= (iLines-1)/iMaxLines +1;
  if(iLines==0)  iPages=0;
  for(i=1; i<=iPages; i++)
  {
    // loop throug query result-lines
    html= "";
    iStartRow= (i-1)*iMaxLines +1;
    iEndRow=   i*iMaxLines;
    if(iEndRow>iLines)  iEndRow= iLines;
    for (iRow= iStartRow; iRow <= iEndRow; iRow++)
    {
      html_tableRowStart(html);
      switch(sMode)
      {
        case "as":
           html += html_makeAlertTableRow(tab[iRow]);
        break;
        case "es":
        default:
          for (iCol = 1; iCol <= dynlen(tab[iRow]); iCol++)
            html_tableCell(html, tab[iRow][iCol], "");
        break;
        }
      html_tableRowEnd(html);
    }
    // Create HTML-page
    htmlPages= htmlBase;
    strreplace(htmlPages, "#pages", iPages);
    strreplace(htmlPages, "#page",  i);
    strreplace(htmlPages, "#lines", iLines);
    if(strpos(htmlPages, "#next")>=0)
    {
      sLink="";
      if(i>1)      // back
      {
        sprintf(sFilename, sFilebase, i-1);
        sLink += " <a href=\""+sFilename+"\">&lt;&lt;&lt;</a> ";
      }
      if(i<iPages) // next
      {
        sprintf(sFilename, sFilebase, i+1);
        sLink += " <a href=\""+sFilename+"\">&gt;&gt;&gt;</a> ";
      }
      strreplace(htmlPages, "#next", sLink);
    }
    strreplace(htmlPages, "#table", html);
    // Save current page
    sprintf(sFilename, sFileset, i);
    iErr= html_save(htmlPages, sFilename, sIP);
  } // of Pages

  // No result lines
  if(iPages<=0)
  {
    html_info(htmlPages, getCatStr("http", "info", http_getLangId(sIP)),
                         getCatStr("http", "noQueryResult", http_getLangId(sIP)) );
  }
  // More then one page
  if(iPages>1)
  {
    // Make select page
    sInfo= getCatStr("http", "selectPage", http_getLangId(sIP));
    html_start(htmlPages, sInfo);
    htmlPages += "<font face=\"arial\" size=\"2\"><center>"+sInfo+": \n";
    for(i=1; i<=iPages; i++)
    {
      sprintf(sFilename, sFilebase, i);
      htmlPages += "<a href=\""+sFilename+"\" target=\"table\">"+i+"</a>";
      if(fmod(i,20)==0)  htmlPages += "<br>\n";
      else if(i<iPages)  htmlPages += " - \n";
      else               htmlPages += "\n";
    }
    htmlPages += "</center></font>";
    html_end(htmlPages);
    // Save select page
    sprintf(sFilename, sFileset, 0);
    iErr= html_save(htmlPages, sFilename, sIP);

    // Make frames for select page
    htmlPages = "<HTML><HEAD><TITLE>Result</TITLE></HEAD>";
    htmlPages += "<FRAMESET bordercolor=#FFFFFF rows=\""+(((iPages-1)/20)*19+33)+",*\" frameborder=1 border=0 framespacing=0>";
    htmlPages += "<FRAME SRC=\"data/http/"+http_getLangDir(sIP)+"/"+sFilename+"\" NAME=\"select\" "+
                 "NORESIZE MARGINWIDTH=3 MARGINHEIGHT=5 SCROLLING=\"NO\">";
    sprintf(sFilename, sFileset, 1);
    htmlPages += "<FRAME SRC=\"data/http/"+http_getLangDir(sIP)+"/"+sFilename+"\" NAME=\"table\" "+
                 "NORESIZE MARGINWIDTH=3 MARGINHEIGHT=5 SCROLLING=\"AUTO\">";
    htmlPages += "</FRAMESET></HTML>";
  }

  // Send answer
  return(htmlPages);
}
//=============================================================================
// WAP: Make and save result WML-Decks
//=============================================================================
// Dirk Hegewisch   30.05.01
//
// This function makes out of an given query-result automaticly one or
// or more WML-sites. This sites where saved with names like given in
// sFileset.
// To bulid this site where used the given wmlBase-file, and the
// given 'key'-strings where replaced. The result is the first WML-Site.
//
// Parameter:
//         tab :  dyn_dyn_anytype  Field with table-values
//   iMaxCards :  int              Max.-numer of cards each WML-Deck
//    sFileset :  string           WML file namen-set (%d for page-number)
//     wmlBase :  string           WML base-site incl. key-strings
//                                 folowing 'key'-string where replaced:
//                    #next      = Navigation one site back/forward
//     Mode=""        #<number>  = Number of result col.
//     mode="as"      #dateTime  = Date and time of Alert
//                    #dpeComment= Langtext of DPE-Comment or DPE-Name
//                    #alertText = Alert-text
//                    #value     = Value
//                    #prio      = Alert prio
//                    #direction = Alert direction
//                    #ackState  = Alert state of acknowledgement
//       sMode :  string           Special-mode / "as"=alert-screen
//  Ret. value :  string           WML-Site the call the result table(s)
//
// Sample:
// string wml;
//    wml= wml_makeResultDecks(tab, "result/page_%d.wml", wmlBase, "as", sIP);
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string wml_makeResultDecks(dyn_dyn_anytype &tab, int iMaxCards, string sFileset,
                           string wmlBase, string sMode, string sIP)
{
int     i, iErr;
string  wml;                 // Result decks
int     iDecks;              // Number of decks
int     iCards;              // Number of result-card
int     iStartCard, iEndCard;  // Start/end card
string  sFilename;           // Deck-filename
string  sFilebase;           // Fileset without path
string  sFilepath;           // Filepath
int     iCard;               // Card counter
int     iRow, iCol;          // Row/col counter
string  sLink;               // Link for page-navigation
string  sTitle;              // Title of result-cards
string  sInfo;

  // Get Filebase
  i= strlen(sFileset);
  while(i>0 && sFileset[i-1]!='/') i--;
  sFilebase= substr(sFileset, i, strlen(sFileset)-i);
  sFilepath= "/data/http/"+substr(http_getLangName(sIP),0,2)+"/"+sFileset;

  // Get title
  if(sMode=="as")
    sTitle= getCatStr("http", "alert", http_getLangId(sIP));
  else
    sTitle= getCatStr("http", "result", http_getLangId(sIP));

  // Number of result Decks
  iCards= dynlen(tab);
  iDecks= (iCards-1)/iMaxCards +1;
  if(iCards==0)  iDecks=0;
  // Loop over Decks
  for(i=1; i<=iDecks; i++)
  {
    // loop throug query result-lines
    wml= "";
    iStartCard= (i-1)*iMaxCards +1;
    iEndCard=   i*iMaxCards;
    if(iEndCard>iCards)  iEndCard= iCards;
    wml_start(wml, sTitle+" "+iStartCard+"/"+iCards, "c"+iStartCard, "");
    for (iCard= iStartCard; iCard <= iEndCard; iCard++)
    {
      iRow= iCards-iCard+1;
      switch(sMode)
      {
        case "as":
          wml += wml_makeAlertCard(wmlBase, tab[iRow]);
        break;
        default:
          for (iCol = 1; iCol <= dynlen(tab[iRow]); iCol++)
            wml += tab[iRow][iCol]+"<br/>\n";
        break;
      }

      // Insert back/next-navigation
      sLink="";
      if(iCard>1)      // back
      {
        if(iCard>iStartCard)
          sprintf(sFilename, "#c%d", iCard-1);
        else
          sprintf(sFilename, sFilepath+"#c%d", i-1, iCard-1);
        sLink += " <a href=\""+sFilename+"\">&lt;&lt;&lt;</a> ";
      }
      if(iCard<iCards) // next
      {
        if(iCard<iEndCard)
          sprintf(sFilename, "#c%d", iCard+1);
        else
          sprintf(sFilename, sFilepath+"#c%d", i+1, iCard+1);
        sLink += " <a href=\""+sFilename+"\">&gt;&gt;&gt;</a> ";
      }
      strreplace(wml, "#next", sLink);

      // New card
      if(iCard<iEndCard)
        wml_newCard(wml, sTitle+" "+(iCard+1)+"/"+iCards, "c"+(iCard+1), "");
    }
    wml_end(wml);

    // Save current deck
    sprintf(sFilename, sFileset, i);
    iErr= html_save(wml, sFilename, sIP);
  } // of Decks

  // No result lines
  if(iDecks<=0)
  {
    wml_info(wml, getCatStr("http", "info", http_getLangId(sIP)),
                  getCatStr("http", "noData", http_getLangId(sIP)) );
  }
  // More then one deck
  if(iDecks>1)
  {
    // Load first deck
    sprintf(sFilename, sFileset, 1);
    iErr= html_load(wml, sFilename, sIP);
  }

  // Send answer
  return(wml);
}


//=============================================================================
// Make alert-table-row
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function makes an alert screen HTML table-row.
//
// Parameter:
//         tab :  dyn_anytype      Alert screen values
//  Ret. value :  string           HTML table-row
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string html_makeAlertTableRow(dyn_anytype &tab)
{
int    i;
string html;
string htmlColor;
string datapoint;
string altime;

  datapoint = tab[1];
  altime =    tab[2];
  http_getColorNameFromColorDB(tab[11], htmlColor);
  for(i=3; i<11; i++)
  {
    if(i==10 && tab[10]!="")
      html_tableAckCell(html, tab[i], datapoint, altime, 0);
    else
    {
      if(i==3 || i==4)
        html_tableCell(html, tab[i], htmlColor);
      else
        html_tableCell(html, tab[i], "");
    }
  }
  return(html);
}
//=============================================================================
// WAP: Make alert-card
//=============================================================================
// Dirk Hegewisch   30.01.01
//
// This function makes an alert card for WAP.
//
// Parameter:
//         tab :  dyn_anytype      Alert row values
//  Ret. value :  string           WML alert-card
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string wml_makeAlertCard(string wml, dyn_anytype tab)
{
  strreplace(wml, "#dateTime",   tab[2]);
  strreplace(wml, "#dpeComment", tab[6]);
  strreplace(wml, "#alertText",  tab[7]);
  strreplace(wml, "#value",      tab[9]);
  strreplace(wml, "#prio",       tab[4]);
  strreplace(wml, "#direction",  tab[8]);
  strreplace(wml, "#ackState",   tab[12]);
  return(wml);
}


//=============================================================================
// DPE detail informations - Get and show all DPE Details
//=============================================================================
// Dirk Hegewisch   29.01.01
//
// Changes: [06.03.01]-[DH]:[TI#10061: Check for alias and give DPEs back]
//------------------------------------------------------------------------------
string dpeCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int    i, iPos, iPos2, iErr;
int    iCount;          // Number of dps
string html, htmlPart;  // Temp. Html-parts
string htmlPage;        // Html-site
string sInfo;           // Info-text
string sDpe;            // Datapoint element
bool   bDpWildcard;     // dp-wildcards
dyn_string asDpe;       // All dps of filter
string sAlias;          // Alias-name of datapoint
langString lsComment;   // Comment of datapoint
string sComment;        // Comment of datapoint
string sValue;          // Value of datapoint element
bool   bValueInvalid;   // Value of datapoint is invalid
string sTime;           // Online-time of datapoint element
langString lsAlert;     // Alert-text
string sAlert;          // Alert-text
bool   bAlertActive;    // Alert is active
string sAlertColor;     // Alert-color
string sHtmlColor;      // HTML alert-color
string sRange;          // PVSS-range of datapoint element
bool   bExceed;         // PVSS-range is exceeded
string sDefault;        // Default-value of datapoint element
bool   bDefaultSet;     // Default-value is Set
int    iType;           // DPE config-type

//DebugN("***Aufruf von dpeCB***");
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  iPos= dynContains(asParameter, "dpe");
  if(iPos>0) sDpe= asValue[iPos];

  // Check for alais-name (TI#10061)
  sAlias= dpAliasToName(sDpe);
  if(sAlias!="")  sDpe= sAlias;

  // Check for dpGroup (new feature with TI#10061)
  if(strpos(sDpe,"*")<0 && (groupNameToDpName(sDpe)!="" || dpTypeName(sDpe)=="_DpGroup"))
  {
  string query;
  dyn_dyn_anytype tab;

    // if we have an group-name get group-dp
    if(!dpExists(sDpe))  sDpe= groupNameToDpName(sDpe);
    sDpe = dpSubStr(sDpe, DPSUB_DP);

    // Form query-string
    query =  "SELECT ";
    query += "'_offline.._value'";
    query += " FROM '{DPGROUP(" + sDpe + ")}'" ;
    query += " WHERE  _LEAF ";
    dpQuery(query, tab);

    // Loop to result-dps
    for(i=2; i<=dynlen(tab); i++)
      dynAppend(asDpe, tab[i][1]);
  }
  else // no group -> get DPEs
  {
    // Check if the datapoint exists
    bDpWildcard= (strpos(sDpe, "*")>=0 || strpos(sDpe, "?")>=0);
    if(!dpExists(sDpe) && !bDpWildcard)
    {
      sprintf(sInfo, getCatStr("http", "errDpNotExist", http_getLangId(sIP)), sDpe);
      html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
      return(html);
    }

    // Check if is only one DPE
    if(bDpWildcard) asDpe= dpNames(sDpe);
    else            asDpe= dpNames(sDpe+"*;");
    iCount= dynlen(asDpe);

    for(i=iCount; i>0; i--)
      if(dpElementType(asDpe[i])==DPEL_STRUCT)
        dynRemove(asDpe, i);
  }

  iCount= dynlen(asDpe);
  // If there no result DPs
  if(iCount<=0)
  {
    sprintf(sInfo, getCatStr("http", "errDpNotExist", http_getLangId(sIP)), sDpe);
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    return(html);
  }

  // Load result base-site
  iErr= html_load(htmlPage, "dpe/dpe_result.html", sIP);
  // if loading fails
  if(iErr<0)
  {
    html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                    getCatStr("http", "loadError", http_getLangId(sIP)) );
    return(html);
  }

  // Get repeat part of site
  iPos=  strpos(htmlPage, "<table");
  iPos2= strpos(htmlPage, "</table>");
  htmlPart= substr(htmlPage, iPos, iPos2-iPos+8);
  strreplace(htmlPage, htmlPart, "#LINK\n#APPEND");

  // loop over dps
  for(i=1; i<=iCount; i++)
  {
    sDpe= asDpe[i];

    // Set site internal link
    html = "<a name=\"" + sDpe + "\"></a>\n" + htmlPart;

    // Add dp-point
    if(strpos(sDpe,".")<0)  sDpe+= ".";

    // Get alias and comment
    sAlias= dpGetAlias(sDpe);
    lsComment= dpGetComment(sDpe);
    sComment= lsComment[http_getLangId(sIP)];
    if(sComment=="")
      sComment= getCatStr("http", "noText", http_getLangId(sIP));
    if(sAlias=="")
      sAlias= getCatStr("http", "noText", http_getLangId(sIP));

    // Check online-config
    dpGet(sDpe+":_original.._type", iType);
    if(iType!=DPCONFIG_NONE)
    {
    time t;
    anytype aValue;
      // Get online -value, -time and -bits
      dpGet(sDpe+":_online.._value",      aValue,
            sDpe+":_online.._stime",      t,
            sDpe+":_online.._bad",        bValueInvalid,
            sDpe+":_online.._default",    bDefaultSet,
            sDpe+":_online.._out_prange", bExceed);
      sValue= dpValToString(sDpe, aValue, true);
      sTime= formatTime(getCatStr("http", "formatTime", http_getLangId(sIP)), t,
                   getCatStr("http", "formatTimeMilli", http_getLangId(sIP)) );
    }
    else
    {
      sValue= getCatStr("http", "noConfig", http_getLangId(sIP));
      sTime= "";
      bValueInvalid= false;
      bDefaultSet= false;
      bExceed= false;
    }

    // Check alert-config
    dpGet(sDpe+":_alert_hdl.._type", iType);
    if(iType!=DPCONFIG_NONE)
    {
      // Get alert -text and -color
      dpGet(sDpe+":_alert_hdl.._act_state_text",   lsAlert,
            sDpe+":_alert_hdl.._act_state_color",  sAlertColor,
            sDpe+":_alert_hdl.._active",           bAlertActive);
      sAlert= lsAlert[http_getLangId(sIP)];
      if(sAlert=="")
        sAlert= getCatStr("http", "noAlertText", http_getLangId(sIP));
      http_getColorNameFromColorDB(sAlertColor, sHtmlColor);
    }
    else
    {
      sAlert= getCatStr("http", "noConfig", http_getLangId(sIP));
      bAlertActive= false;
      sHtmlColor= "";
    }

    // Check PVSS range-config
    dpGet(sDpe+":_pv_range.._type", iType);
    if(iType!=DPCONFIG_NONE)
    {
    float  fMin, fMax;
    bool   bNeg;
      dpGet(sDpe+":_pv_range.._min", fMin,
            sDpe+":_pv_range.._max", fMax,
            sDpe+":_pv_range.._neg", bNeg);
      if(!bNeg)
        sprintf(sRange, getCatStr("http", "rangeFormat", http_getLangId(sIP)),
                        fMin, fMax);
      else
        sprintf(sRange, getCatStr("http", "rangeFormatNeg", http_getLangId(sIP)),
                        fMin, fMax);
    }
    else
      sRange= getCatStr("http", "noConfig", http_getLangId(sIP));

    // Check default-value config
    dpGet(sDpe+":_default.._type", iType);
    if(iType!=DPCONFIG_NONE)
    {
    anytype aValue;
      dpGet(sDpe+":_default.._value", aValue);
      sDefault= dpValToString(sDpe, aValue, true);
    }
    else
      sDefault= getCatStr("http", "noConfig", http_getLangId(sIP));

    // Create HTML-part
    strreplace(html, "#dpe",          sDpe);
    strreplace(html, "#alias",        sAlias);
    strreplace(html, "#comment",      sComment);
    strreplace(html, "#valueInvalid", (bValueInvalid)?"led_invalid":"led_off");
    strreplace(html, "#value",        sValue);
    strreplace(html, "#time",         sTime);
    strreplace(html, "#alertActive",  (bAlertActive)?"led_active":"led_off");
    strreplace(html, "#alertColor",   sHtmlColor);
    strreplace(html, "#alert",        sAlert);
    strreplace(html, "#exceed",       (bExceed)?"led_alert":"led_off");
    strreplace(html, "#range",        sRange);
    strreplace(html, "#defaultSet",   (bDefaultSet)?"led_alert":"led_off");
    strreplace(html, "#default",      sDefault);

    if(iCount>1)
      html += "<a href=\"#top\">" + getCatStr("http", "top", http_getLangId(sIP)) + "</a>\n";

    // Append repeat part of site
    if(i<iCount)
      html += "\n<hr size=\"3\">\n#APPEND";
    strreplace(htmlPage, "#APPEND", html);
  }

  // Make internal site links
  if(iCount>1)
  {
    html =  "<a name=\"top\"></a>\n";
    html += "<table border=\"0\">\n";
    html += " <tr><th>" + getCatStr("http", "selectDpe", http_getLangId(sIP)) + "</th></tr>\n";
    for(i=1; i<=iCount; i++)
      html += " <tr><td><a href=\"#" + asDpe[i] + "\">" +
               dpSubStr(asDpe[i], DPSUB_DP_EL) + "</a></td></tr>\n";
    html += "</table><hr size=\"3\">\n";
    strreplace(htmlPage, "#LINK", html);
  }
  else
    strreplace(htmlPage, "#LINK", "");

  // Give back result-site
  return(htmlPage);
}
//=============================================================================
// WAP: DPE detail informations - Get and show all DPE Details
//=============================================================================
// Dirk Hegewisch   06.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string dpeWapCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int    i, iPos, iErr;
int    iCount;          // Number of dps
string wml;             // Temp. Wml-parts
string wmlPage;         // Wml-site
string sInfo;           // Info-text
string sDpe;            // Datapoint element
bool   bDpWildcard;     // dp-wildcards
dyn_string asDpe;       // All dps of filter
string sAlias;          // Alias-name of datapoint
string sTitle;          // Title of wml result-site

//DebugN("***Aufruf von dpeWapCB***");
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  // Get parameters
  iPos= dynContains(asParameter, "dpe");
  if(iPos>0) sDpe= asValue[iPos];

  // Check for alais-name
  sAlias= dpAliasToName(sDpe);
  if(sAlias!="")  sDpe= sAlias;

  // Check for dpGroup
  if(groupNameToDpName(sDpe)!="" || dpTypeName(sDpe)=="_DpGroup")
  {
  string query;
  dyn_dyn_anytype tab;
  langString ls;

    // if we have an group-name get group-dp
    if(!dpExists(sDpe))  sDpe= groupNameToDpName(sDpe);
    sDpe = dpSubStr(sDpe, DPSUB_DP_EL);

    // Form query-string
    query =  "SELECT ";
    query += "'_offline.._value'";
    query += " FROM '{DPGROUP(" + sDpe + ")}'" ;
    query += " WHERE  _LEAF ";
    dpQuery(query, tab);

    // Loop to result-dps
    for(i=2; i<=dynlen(tab); i++)
      dynAppend(asDpe, tab[i][1]);

    // Get title from comment
    ls= groupDpNameToName(sDpe);
    sTitle= ls[http_getLangId(sIP)];
  }
  else // no group -> get DPEs
  {
    // Check if the datapoint exists
    bDpWildcard= (strpos(sDpe, "*")>=0 || strpos(sDpe, "?")>=0);
    if(!dpExists(sDpe) && !bDpWildcard)
    {
      sprintf(sInfo, getCatStr("http", "errDpNotExist", http_getLangId(sIP)), sDpe);
      wml_info(wml, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
      return(wml);
    }

    // Check if is only one DPE
    if(bDpWildcard) asDpe= dpNames(sDpe);
    else            asDpe= dpNames(sDpe+"*;");
    iCount= dynlen(asDpe);

    for(i=iCount; i>0; i--)
      if(dpElementType(asDpe[i])==DPEL_STRUCT)
        dynRemove(asDpe, i);

    sTitle= getCatStr("http", "valueDisplay", http_getLangId(sIP));
    http_appendRecentDpe(sDpe);
  }

  iCount= dynlen(asDpe);
  // If there no result DPs
  if(iCount<=0)
  {
    sprintf(sInfo, getCatStr("http", "errDpNotExist", http_getLangId(sIP)), sDpe);
    wml_info(wml, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    return(wml);
  }

  // Load result base-site
  iErr= html_load(wmlPage, "dpe/dpe_result.wml", sIP);
  // if loading fails
  if(iErr<0)
  {
    wml_info(wml, getCatStr("http", "warning", http_getLangId(sIP)),
                  getCatStr("http", "loadError", http_getLangId(sIP)) );
    return(wml);
  }

  // loop over dps
  for(i=1; i<=iCount; i++)
  {
    sDpe= asDpe[i];
    if(strpos(sDpe,".")<0)  sDpe+= ".";
    // Get value and add result-line
    {
    anytype aValue;
      dpGet(sDpe+":_online.._value", aValue);
      wml += http_formatResultValue(sDpe, aValue, sIP);
    }
    // check for 1k limit of wml-site
    if(strlen(wmlPage)+strlen(wml)>950)
    {
      wml += "<b>...</b><br/>\n";
      break;
    }
  } // off loop dps

  strreplace(wmlPage, "#title",  sTitle);
  strreplace(wmlPage, "#result", wml);

  // Give back result-site
  return(wmlPage);
}


//=============================================================================
// WAP: Format value of DPE with comment and unit like
//   <Comment or DPE>= <Value><Unit>
//=============================================================================
// Dirk Hegewisch   06.06.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string http_formatResultValue(string sDpe, anytype aValue, string sIP)
{
string     sValue;
langString lsComment;
string     sResult;
bool       bCut;

  // Cut value to 30 Chars and first element
  sValue= aValue;
  if(strpos(sValue, " |")>0)
  {
    sValue= substr(sValue, 0, strpos(sValue, " |") );
    bCut= true;
  }
  if(strlen(sValue)>30)
  {
    sValue= substr(sValue, 0, 30);
    bCut= true;
  }

  // Use commenttext
  lsComment= dpGetComment(sDpe);
  sResult= lsComment[http_getLangId(sIP)];
  // In case of no commet use DPE
  if(sResult=="")  sResult= dpSubStr(sDpe, DPSUB_DP_EL);

  sResult += "=<br/><b>";
  // Format value with unit.
  if(!bCut)
    sResult += dpValToString(sDpe, aValue, true);
  else
    sResult += sValue + " " + dpGetUnit(sDpe) + "...";
  sResult += "</b><br/>\n";
  return(sResult);
}


//=============================================================================
// PVSS-HTML-Reference - Interpreter to form result HTML-Site
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string pvssHtmlRefCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int    iPos, iErr;
string html;            // Html-site
string sRefFile;        // HTML-Refernce File
string sInfo;           // Info-text

  // DebugN("asParameter = ", asParameter );

  iPos= dynContains(asParameter, "ref");
  if ( iPos <= 0 )
  {
    // Spezialbehandlung Hauptmenue:
    iPos= dynContains(asParameter, "mainRef");
  }

  if(iPos>0)
  {
    sRefFile= asValue[iPos];
    // TI#10060: Eleminate 'Ref'
    if(substr(sRefFile, strlen(sRefFile)-3)=="Ref")
      sRefFile= substr(sRefFile, 0, strlen(sRefFile)-3);

    if ( asParameter[iPos] == "mainRef" )
    {
      // setTrace(2);
      string html;
      iErr= (html_load(html, sRefFile+"Ref", sIP)) ? -1 : 0;

      if ( iErr == 0 )
      {
        iErr = ( http_addAppl2Menu( html, http_getLangDir(sIP) ) ) ? -1 : 0;
      }

      if ( iErr == 0 )
      {
        int i;
        dyn_string asDollar;

        // Make set of $-parameters
        for(i=1; i<=dynlen(asParameter); i++)
          asDollar[i]= "$"+asParameter[i]+":"+asValue[i];
        // Append other usefull Parameters
        dynAppend(asDollar, "$User:"+sUser);
        dynAppend(asDollar, "$Ip:"+sIP);
        dynAppend(asDollar, "$LangId:"+http_getLangId(sIP) );
        // DebugN(asDollar);

        // call replace Funktion
        html_replaceParameters(html, asDollar, sIP, sUser);

        iErr= (html_save(html, sRefFile, sIP) ) ? -2 : 0;
      }

      // setTrace(0);
    }
    else
    {
      dynRemove(asParameter, iPos);
      dynRemove(asValue,     iPos);
      html_loadReference(sRefFile, asParameter, asValue, sIP, sUser, iErr);
    }

    if(iErr>=0)
    {
      // Forwarding HTML-site
      html= html_forward(sRefFile, 0, sIP);
    }
    else if(iErr==-1) // Error on loading
    {
      sprintf(sInfo,  getCatStr("http", "errFileLoad", http_getLangId(sIP)), sRefFile+"Ref");
      html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    }
    else if(iErr==-2) // Error on saveing
    {
      sprintf(sInfo,  getCatStr("http", "errFileSave", http_getLangId(sIP)), sRefFile);
      html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    }
  }
  else
  {
    sprintf(sInfo,  getCatStr("http", "paraMissing", http_getLangId(sIP)), "ref");
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
  }
  return(html);
}
//=============================================================================
// WAP! PVSS-HTML-Reference - Interpreter to form result HTML-Site
//=============================================================================
// Dirk Hegewisch   28.05.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string pvssHtmlRefWapCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int    iPos, iErr;
string html;            // Html-site
string sRefFile;        // HTML-Refernce File
string sInfo;           // Info-text

  iPos= dynContains(asParameter, "ref");
  if(iPos>0)
  {
    sRefFile= asValue[iPos];
    // TI#10060: Eleminate 'Ref'
    if(substr(sRefFile, strlen(sRefFile)-3)=="Ref")
      sRefFile= substr(sRefFile, 0, strlen(sRefFile)-3);
    dynRemove(asParameter, iPos);
    dynRemove(asValue,     iPos);
    html_loadReference(sRefFile, asParameter, asValue, sIP, sUser, iErr);
    if(iErr>=0)
    {
      // Load WML-Site
      html_load(html, sRefFile, sIP);
    }
    else if(iErr==-1) // Error on loading
    {
      sprintf(sInfo,  getCatStr("http", "errFileLoad", http_getLangId(sIP)), sRefFile+"Ref");
      wml_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    }
    else if(iErr==-2) // Error on saveing
    {
      sprintf(sInfo,  getCatStr("http", "errFileSave", http_getLangId(sIP)), sRefFile);
      wml_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
    }
  }
  else
  {
    sprintf(sInfo,  getCatStr("http", "paraMissing", http_getLangId(sIP)), "ref");
    wml_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
  }
  return(html);
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


//=============================================================================
// Convert the Alert-query-result table
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//=============================================================================
dyn_dyn_anytype convertAlertTab(dyn_dyn_anytype &tab, string sIP)
{
int i, iId;
dyn_dyn_string ret;
langString     lsComment, lsText;
string         sDpe, sDpeLang, sText;
string         sDir, sAck, sAckStr;
time           t;
int            iPrio;

  // Get language-ID
  iId= http_getLangId(sIP);
  for(i=2; i<=dynlen(tab); i++)
  {
    t= tab[i][2];
    iPrio= tab[i][4];
    sDpe= tab[i][1];
    lsComment= dpGetComment(sDpe);
    sDpeLang= lsComment[iId];
    lsText= tab[i][5];
    sText= lsText[iId];

    if(sDpeLang=="")
      sDpeLang= dpSubStr(sDpe, DPSUB_DP_EL);

    if(tab[i][6] == 1) sDir= getCatStr("sc", "entered", http_getLangId(sIP) );
    else               sDir= getCatStr("sc", "left",    http_getLangId(sIP) );

    if(tab[i][8]==DPATTR_ACKTYPE_SINGLE)          sAck= "x";
    else if(tab[i][8] == DPATTR_ACKTYPE_MULTIPLE) sAck= "xxx";
    else
    {
      if(tab[i][11])  // _ackable
        sAck= tab[i][13] ? "!!!":"!";  // oldest Ack
      else
        sAck= tab[i][12] ? "---":"/";  // _ack_oblig
    }
    if(strpos(sAck,"x")==0)       sAckStr= getCatStr("http", "ack",   http_getLangId(sIP) );
    else if(strpos(sAck,"!")==0)  sAckStr= getCatStr("http", "unack", http_getLangId(sIP) );
    else                          sAckStr= sAck;

    ret[i-1][1]=  tab[i][1];
    ret[i-1][2]=  tab[i][2];
    ret[i-1][3]=  tab[i][3];            // short-sign
    ret[i-1][4]=  iPrio;                // priority
    ret[i-1][5]=  formatTime(getCatStr("http", "formatTime", http_getLangId(sIP)), t,
                        getCatStr("http", "formatTimeMilli", http_getLangId(sIP)) );
    ret[i-1][6]=  sDpeLang;             // dpe
    ret[i-1][7]=  sText;                // alert-text
    ret[i-1][8]=  sDir;                 // direction
    ret[i-1][9]=  dpValToString(sDpe, tab[i][7], true);  // value
    ret[i-1][10]= "<center>"+sAck+"</center>";   // acknowledge
    ret[i-1][11]= tab[i][10];
    ret[i-1][12]= sAckStr;
  }
  return(ret);
}


//=============================================================================
// Convert the Event-query-result table
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// Changes: [Date]-[Name]:[Changes]
//=============================================================================
dyn_dyn_anytype convertEventTab(dyn_dyn_anytype &tab, string sIP)
{
int i, iId;
dyn_dyn_string ret;
time           t;
langString     lsComment, lsText;
string         sDpe, sDpeLang, sText;

  // Get language-ID
  iId= http_getLangId(sIP);
  for (i=2; i<=dynlen(tab); i++)
  {
    t= tab[i][2];
    sDpe=tab[i][1];
    lsComment= dpGetComment(sDpe);
    lsText= tab[i][5];
    sText= lsText[iId];
    sDpeLang= lsComment[iId];
    if(sDpeLang=="")
      sDpeLang= dpSubStr(sDpe, DPSUB_DP_EL);
    ret[i-1][1]= formatTime(getCatStr("http", "formatTime", http_getLangId(sIP)), t,
                       getCatStr("http", "formatTimeMilli", http_getLangId(sIP)) );
    ret[i-1][2]= sDpeLang;                  // dpe
    ret[i-1][3]= dpValToString(sDpe, tab[i][3], true);  // value
    ret[i-1][4]= sText;                     // text
    ret[i-1][5]= convertStatus(tab[i][4]);  // status
    // if no Text give use the value
    if(ret[i-1][4]=="")  ret[i-1][4]= ret[i-1][3];
  }
  return(ret);
}


//=============================================================================
// Acknowledge the given alert-Dp
//=============================================================================
// Dirk Hegewisch   22.01.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string acknowledgeAlertCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iErr, iPos;
string  html;
string  sDp;
string  sInfo;

//DebugN("***Aufruf von acknowledgeAlertCB***");
//for(i=1; i<=dynlen(asParameter); i++)
//  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  iPos= dynContains(asParameter, "dp");
  if(iPos>0) sDp= asValue[iPos];
  if(!dpExists(sDp))  // dp does not exists
  {
    sprintf(sInfo,  getCatStr("http", "dpNotExist", http_getLangId(sIP)), sDp);
    html_info(html, getCatStr("http", "error", http_getLangId(sIP)), sInfo);
  }
  // Check for acknowledgement permission
  else if(! getUserPermission(5, getUserId(sUser) ) )
  {
    html_info(html, getCatStr("http", "warning", http_getLangId(sIP)),
                    getCatStr("http", "noAck", http_getLangId(sIP)) );
  }
  else
  {
    // Do the acknowledgement
    dpSet(sDp+":_alert_hdl.._ack", 2);
    sprintf(sInfo,  getCatStr("http", "ackOk", http_getLangId(sIP)), sDp);
    html_info(html, getCatStr("http", "info", http_getLangId(sIP)), sInfo);
  }
  // Append close button
  strreplace(html, "</center>",
            "\n<p><form><input type=\"button\" name=\"close\" value=\"" +
            getCatStr("http", "close", http_getLangId(sIP)) +
            "\" onClick=\"self.close();\"></form></p>\n</center>" );
  return(html);
}
//=============================================================================
// WAP Acknowledge the given alert-Dp
//=============================================================================
// Dirk Hegewisch   29.05.01
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
string acknowledgeAlertWapCB(dyn_string asParameter, dyn_string asValue, string sUser, string sIP)
{
int     i, iErr, iPos;
string  wml;
string  sDp;
string  sInfo;

// Until jet not implemeted.
DebugN("***Aufruf von acknowledgeAlertWapCB***");
for(i=1; i<=dynlen(asParameter); i++)
  DebugN(asParameter[i]+"= ["+asValue[i]+"]");

  iPos= dynContains(asParameter, "dp");
  if(iPos>0) sDp= asValue[iPos];
  if(!dpExists(sDp))  // dp does not exists
  {
    sprintf(sInfo, getCatStr("http", "dpNotExist", http_getLangId(sIP)), sDp);
    wml_info(wml,  getCatStr("http", "error", http_getLangId(sIP)), sInfo);
  }
  // Check for acknowledgement permission
  else if(! getUserPermission(5, getUserId(sUser) ) )
  {
    wml_info(wml, getCatStr("http", "warning", http_getLangId(sIP)),
                  getCatStr("http", "noAck", http_getLangId(sIP)) );
  }
  else
  {
    // Do the acknowledgement
    dpSet(sDp+":_alert_hdl.._ack", 2);
    sprintf(sInfo, getCatStr("http", "ackOk", http_getLangId(sIP)), sDp);
    wml_info(wml,  getCatStr("http", "info", http_getLangId(sIP)), sInfo);
  }
  return(wml);
}


//=============================================================================
// Convert Status-bits to Status-string
//=============================================================================
string convertStatus(bit32 status)
{
string text;

  text +=  dpGetStatusBit(status, ":_offline.._default")  ? "D" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._invalid")  ? "I" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._from_GI")  ? "G" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit1")  ? "1" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit2")  ? "2" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit3")  ? "3" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit4")  ? "4" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit5")  ? "5" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit6")  ? "6" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit7")  ? "7" : "-";
  text +=  dpGetStatusBit(status, ":_offline.._userbit8")  ? "8" : "-";
  return text;
}


//=============================================================================
// Search and replace PVSS-Parameter in given HTML-Reference
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function loads the given HTML refernce-site with the sFilename.
// Searched for PVSS-statements, interprets and replaced them.
// After all the html-String was saved as Html-file.
//
// Parameter:
//   sFilename :  string      File name
// asParameter :  dyn_string  Parameter-name  field
//     asValue :  dyn_string  Parameter-value field
//        iRet :  int         Error-code (0= Success)
//
// Sample:
// int iErr;
//    html_loadReference("es/es_base.html", asParameter, asValues,
//                            sIP, sUser, iErr);
//
// Changes: [30.04.01]-[DH]:[TI#9402: Now Call - html_replaceParameters()]
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
void html_loadReference(string sFilename, dyn_string asParameter, dyn_string asValue,
                        string sIP, string sUser, int &iRet)
{
int    i, j;
int    iErr;           // Errorhandler
string html;           // HTML-Code (Site)
dyn_string  asDollar;  // Set of $-Parameters

  // Load reference
  iErr= html_load(html, sFilename+"Ref", sIP);
  if(iErr) // Error on loading
  {
    iRet= -1;
    return;
  }

  // Make set of $-parameters
  for(i=1; i<=dynlen(asParameter); i++)
    asDollar[i]= "$"+asParameter[i]+":"+asValue[i];
  // Append other usefull Parameters
  dynAppend(asDollar, "$User:"+sUser);
  dynAppend(asDollar, "$Ip:"+sIP);
  dynAppend(asDollar, "$LangId:"+http_getLangId(sIP) );
//DebugN(asDollar);

  // call replace Funktion
  html_replaceParameters(html, asDollar, sIP, sUser);

  // Save HTML-Site
  iErr= html_save(html, sFilename, sIP);
  if(iErr) // Error on saving
  {
    iRet= -2;
    return;
  }
  // Success
  iRet= 0;
}


//=============================================================================
// To get an PVSS-Time of the Parameterset
//=============================================================================
// Dirk Hegewisch   15.01.01
//
// This function searched in the HTTP parameter-set all time fields
// with the name-key 'sTime'. And builds out of it an PVSS time-var
// and delets the founded parameters out of the parameter-list.
//
// Parameter:
//       sTime :  string      Time-field prefix (example: 't1')
// asParameter :  dyn_string  Parameter-name  field
//    asValues :  dyn_string  Parameter-value field
//  Ret. value :  time        Return value of time or time interval
//
// Example:
// time tStart;
//    tStart= getTimeFromParameter("t1", asParameter, asValues);
//    DebugN(tStart);
//
// Changes: [Date]-[Name]:[Changes]
//------------------------------------------------------------------------------
time getTimeFromParameter(string sTime, dyn_string &asParameter, dyn_string &asValue)
{
int i;
dyn_int aiTime;
dyn_string asTimePara= makeDynString("Year", "Month", "Day",
                                     "Hour", "Minute", "Second", "Msec");
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
                     aiTime[4],aiTime[5],aiTime[6],aiTime[7]) );
  // time-interval given
  else
    return( aiTime[3]*86400 + aiTime[4]*3600 +
            aiTime[5]*60 + aiTime[6] + 0.001*aiTime[7] );
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
void http_setGlobals()
{
   // Initializise config parameter and values
  addGlobal("gasConfigParameter", DYN_STRING_VAR);
  addGlobal("gasConfigValue",     DYN_STRING_VAR);

  // Memory the choosen language form start-site
  addGlobal("gasIP",       DYN_STRING_VAR);
  addGlobal("gasLangName", DYN_STRING_VAR);
  addGlobal("gaiLangId",   DYN_INT_VAR);
  addGlobal("gasLangDir",  DYN_STRING_VAR);
  addGlobal("gasLoginIP",  DYN_STRING_VAR);
  addGlobal("gatLoginTime",DYN_TIME_VAR);

  // additional applications in main menu
  addGlobal("gasAddAppLang", DYN_STRING_VAR);
  addGlobal("gasAddAppLink", DYN_STRING_VAR);
  addGlobal("gasAddAppText", DYN_STRING_VAR);
  addGlobal("gasAddAppTip", DYN_STRING_VAR);
  addGlobal("gaiAddAppNewWin", DYN_INT_VAR);

}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// newWindow: 1 = new Window (target="_blank"), 2 = target="_top"
void http_addMenuAppl(string sLangDir, string sLink, string sText, string sTip, int newWindow)
{
  dynAppend(gasAddAppLang, sLangDir);
  dynAppend(gasAddAppLink, sLink);
  dynAppend(gasAddAppText, sText);
  dynAppend(gasAddAppTip,  sTip);
  dynAppend(gaiAddAppNewWin, newWindow);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
int http_addAppl2Menu(string & html, string sLangDir)
{
  int i, nApps, rc;
  string sTarget;
  string sTip;

  dyn_string tableRowNames;
  dyn_dyn_string tableValues;

  // setTrace(2);
  // DebugN("sLangDir = " + sLangDir );

  tableRowNames = makeDynString("$menuHref","$menuLinkTarget", "$menuText","$menuTip");
  dynClear(tableValues);

  nApps=1;
  for ( i = 1; i <= dynlen(gasAddAppLang); i++ )
  {
    // DebugN("i = " + i, "gasAddAppLang[i] = " + gasAddAppLang[i] );

    if ( gasAddAppLang[i] == sLangDir )
    {
      sTip = gasAddAppTip[i];
      if ( sTip != "" )
      {
        sTip = "(" + sTip + ")";
      }
      sTarget="";
      if ( gaiAddAppNewWin[i] == 1 )
      {
        sTarget=" target=\"_blank\" ";
      }
      else if ( gaiAddAppNewWin[i] == 2 )
      {
        sTarget=" target=\"_top\" ";
      }

      tableValues[nApps] =makeDynString(gasAddAppLink[i], sTarget, gasAddAppText[i], sTip);
      // DebugN("nApps = " + nApps, "tableValues[nApps] = ", tableValues[nApps] );

      nApps++;
    }
  }

  // DebugN( tableRowNames, tableValues);

  // setTrace(0);

  rc = ( html_replaceListParameters( html, tableRowNames, tableValues, -1, "", "" ) < 0 ) ? -1 : 0;

  // DebugTN(" rc = " + rc , "html = " + html );

  return rc;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
void http_makePathes()
{
  int i;

  // Make paths if http not existing

	dyn_string asPath;    // List of Paths
	string     sLangDir;  // Language-Pathname

	// List of paths
	asPath= makeDynString(DATA_PATH+"http/temp",
												DATA_PATH+"http/download",
												DATA_PATH+"http/java",
												DATA_PATH+"http/start",
												DATA_PATH+"http/style",
												PROJ_PATH+"pictures/http/flags");
	// Add language-paths to list
	for (i=0; i<getNoOfLangs(); i++)
	{
		sLangDir= getLocale(i);
		sLangDir= DATA_PATH + "http/" + substr(sLangDir, 0, strpos(sLangDir, "_") ) + "/";
		dynAppend(asPath, makeDynString(sLangDir+"as/result",
																		sLangDir+"es/result",
																		sLangDir+"query/result",
																		sLangDir+"dpe",
																		sLangDir+"diagnostics",
																		sLangDir+"refs/examples") );
	}

	// Create directorys
	for(i=1; i<=dynlen(asPath); i++)
	{
    if( access(asPath[i], F_OK) == -1 )
    {
		  // DebugN("makePath: ", asPath[i]);
		  if(_WIN32)
		  {
			  strreplace(asPath[i], "/", "\\");
			  system("cmd /c md "+asPath[i]);
		  }
		  else if(_UNIX)
		  {
			  strreplace(asPath[i], "\\", "/");
			  system("mkdir -p "+asPath[i]);
      }
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
void http_Connects()
{
  string cVal;
  string cKey;
  int i;

  // Startup / Get language form start-site
  httpConnect("startCB", "/");
  httpConnect("startWapCB", "/wap", "text/vnd.wap.wml");

  // Help for HTTP-Server [16.07.01]-[DH]:[TI#9096]
  httpConnect("helpCB", "/help");

  // Get Alert-table
  httpConnect("alertsCB", "/AlertQuery");
  httpConnect("alertsWapCB", "/AlertWap", "text/vnd.wap.wml");
  httpConnect("acknowledgeAlertCB", "/Acknowledge");
  httpConnect("acknowledgeAlertWapCB", "/AcknowledgeWap", "text/vnd.wap.wml");
  addGlobal("gcAsFileRing", CHAR_VAR);
  gcAsFileRing= "a";

  // Get historical-events
  httpConnect("eventsCB", "/EventQuery");
  addGlobal("gcEsFileRing", CHAR_VAR);
  gcEsFileRing= "a";

  // Get detail informations of DPEs
  httpConnect("dpeCB", "/DPE");
  httpConnect("dpeWapCB", "/DPE_WAP", "text/vnd.wap.wml");

  // PVSS-HTML-Referenz
  httpConnect("pvssHtmlRefCB", "/PVSS");
  httpConnect("pvssHtmlRefWapCB", "/PVSS_WAP", "text/vnd.wap.wml");

  // Get HTML-Table from PVSS-query
  httpConnect("queryCB", "/Query");

  // Additional connects from config file
  cVal="init";
  for ( i=0; i<100 && cVal != "" ; i++ )
  {
    sprintf(cKey,"httpConnect%d", i);
    //DebugN(".. searching for config key " + cKey );

    cVal=http_getConfig(cKey);
    if ( cVal != "" )
    {
      dyn_string params;
      string work, rsrc, cType;

      // parameter sind durch "," getrennt:
      params=strsplit(cVal, ",");
      if ( dynlen(params) >= 2 )
      {
        work = strltrim(strrtrim(params[1]));
        rsrc = strltrim(strrtrim(params[2]));
      }
      if ( dynlen(params) >= 3 )
      {
        cType = strltrim(strrtrim(params[3]));
        DebugN("Additional connects: connecting resource '" + rsrc + "' with CTRL function " + work + ", Type: " + cType);

        httpConnect(work, rsrc, cType);

      }
      else if ( dynlen(params) == 2 )
      {
        DebugN("Additional connects: connecting resource '" + rsrc + "' with CTRL function " + work);
        httpConnect(work, rsrc);
      }
    }
  }
}

