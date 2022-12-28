#uses "dist"
#uses "CtrlHTTP"
#uses "CtrlXml"
#uses "CtrlPv2Admin"
#uses "dpDyn"
#uses "classes/auth/OaAuthServerside"
#uses "std"

// FMCS - AMS, SPC...
#uses "FMCS_WebserverLib"
#uses "FMCSLibs/SPC"
#uses "FMCSLibs/AMS"
#uses "FMCSLibs/CRIS"
// --

const string MOBILE_UI_PRAEFIX_DP = "_UiDevices";
const string MOBILE_UI_PRAEFIX_DP_2 = "_UiDeviceMgmt";
int iLowestAutoManNumMobileUI;

mapping mUiUuid;

const string NOT_FOUND = "<html><head><title>Error</title></head>"
                         "<body><h1>Not found</h1>"
                         "The requested resource was not found</body></html>";

// this script is needed for the WebClient-caching functionality
//--------------------------------------------------------------------------------

bool isServerSideLoginEnabled = FALSE;
mixed authServerSide;
int  httpsPort;
bool ulcNeedAuth;

/* config entry
[webClient]
clientProjExt = 0 #default = 0
*/
const int PORJNAMEEXTENSION_NO = 0; //default - use just project name of server
const int PORJNAMEEXTENSION_HOSTNAME = 1; //exend with _host1
const int PORJNAMEEXTENSION_REDUHOSTNAMES = 2; //exend with _host1_host2

string g_sProjExtension;

main()
{
  iLowestAutoManNumMobileUI = paCfgReadValueDflt(getPath(CONFIG_REL_PATH, "config"), "webClient", "LowestAutoManNumMobileUI", 200);

  dpQueryConnectSingle("dpGetCacheConnectCB", FALSE, "_MobileDeviceManagment",
                       "SELECT '_online.._value' FROM '" + MOBILE_UI_PRAEFIX_DP + ".**' WHERE _LEAF");

  string user;

  // We only need the OS user on unix
  if (!_WIN32)
  {
    mapping userInfo = getOSUser();

    if (mappingHasKey(userInfo, "Name"))
    {
      user = userInfo["Name"];
    }
  }

  // IM 114727: add config entry for webClient ports and authentification
  int httpPort;
  mixed httpAuth = false;
  int httpAuthCfg;

  bool httpAuthCfgExists = !paCfgReadValue(getPath(CONFIG_REL_PATH)+"config", "webClient", "httpAuth", httpAuthCfg);
  httpAuth = httpAuthCfgExists && (httpAuthCfg == 1);
  ulcNeedAuth = httpAuth;

  if ( _WIN32 || (user == "root") )
  {
    httpPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH)+"config", "webClient", "httpPort", 80);
    httpsPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH)+"config", "webClient", "httpsPort", 443);
  }
  else
  {
    // on unix, ports < 1024 are not available for non-root users
    // therefore open alternative ports
    httpPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH)+"config", "webClient", "httpPort", 8080);
    httpsPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH)+"config", "webClient", "httpsPort", 8079);
  }

  initHosts();
  switch(paCfgReadValueDflt(getPath(CONFIG_REL_PATH)+"config", "webClient", "clientProjExt", PORJNAMEEXTENSION_NO))
  {
    case PORJNAMEEXTENSION_HOSTNAME:
      g_sProjExtension = "_" + host1;
      break;
    case PORJNAMEEXTENSION_REDUHOSTNAMES:
      g_sProjExtension = "_" + host1 + "_" + host2;
      break;
    default:
      //PORJNAMEEXTENSION_NO
      break;
  }

  OaAuthServerside auth;
  authServerSide = auth;
  isServerSideLoginEnabled = authServerSide.isServerSideAuthEnabled();

  if (isServerSideLoginEnabled)
  {
    //when a ui manager goes online or offline we need to handle this
    dpConnect("cbHandleUiConnections", FALSE, "_Connections.Ui.ManNums", "_Connections_2.Ui.ManNums");
    //connect to SessionTokenTemp to handle tokens coming from more than one
    dpConnect("cbHandleSessionTokens", FALSE, "_System.Auth.SessionTokenInterface");

    //Server Side Login requires the 'Basic' authentication method
    httpAuth = "Basic";

    if (httpsPort == 0)
    {
      throwError(makeError("", PRIO_SEVERE, ERR_PARAM, 54, "Server Side Authentication requires HTTPS"));
      return;
    }
  }
  else if (!httpAuthCfgExists)
  {
    // SSO requires 'Negotiate' authentication method, this is only selected
    // when there is no httpAuth config entry
    OaAuthFactory authFactory;
    anytype auth = authFactory.getAuth();
    if (auth.getBaseType() == "OaAuthMethodAD")
    {
      // OS authentication is activated - this doesn't mean that SSO is activated as well,
      // but further checks are based on the user that tries to log in.
      // The only thing that can be checked is whether the SSO bit is set for this server
      // for at least one group.

      const int SSO_BIT = 31; // bit 32 is on index 31
      string hostname = getHostname();

      // get WS permissions
      dyn_string displayNames;
      dyn_bit32 permissions;
      dpGet("_WsPermission.Permission",  permissions, "_WsPermission.DisplayName", displayNames);

      if (dynlen(permissions) < dynlen(displayNames))
        permissions[dynlen(displayNames)] = 0;

      bool ssoBitSet = false;
      for (int i = 1; i <= dynlen(displayNames); i++)
      {
        if (stricmp(hostname, displayNames[i]) == 0)
        {
          if (getBit(permissions[i], SSO_BIT))
          {
            // there's at least one group for which the SSO_BIT is set for this server,
            // so SSO is potentially possible - use "Negotiate" method so that SSO does
            // work if actually enabled
            ssoBitSet = true;
            break;
          }
        }
      }

      if (ssoBitSet)
      {
        httpAuth = "Negotiate";
        DebugFTN("HTTP", "HTTP authentication method set to Negotiate");
      }
      else
      {
        DebugFTN("HTTP", "OS user authentication activated, but SSO bit not set for this host");
      }
    }
  }

  int rc = httpServer(httpAuth, httpPort, httpsPort);  // start http Server
  httpSetPermission("/data/ulc/login/*", makeMapping("authType", ""));
  httpSetPermission("/data/ulc/shared/*", makeMapping("authType", ""));
  httpSetPermission("/pictures/*", makeMapping("authType", ""));
  httpSetPermission("/data/ulc/start.html", makeMapping("authType", ""));
  httpSetPermission("/favicon.ico", makeMapping("authType", ""));
  httpSetPermission("/data/html/js/vendor/*", makeMapping("authType", ""));

  httpSetPermission("/authInfo", makeMapping("authType", ""));
  httpConnect("authInfo", "/authInfo");
  httpConnect("handleUlcLogin", "/data/ulc/login/index.html");

  if (rc == 0)  // http server installed
  {
    int i_logSize, i_contentSize;

    // check if the maxLogFileSize was set in the config file
    paCfgReadValue(getPath(CONFIG_REL_PATH) + "config", "general", "maxLogFileSize", i_logSize);

    // if no value was defined use the default of 10 MB
    if (i_logSize == 0)
      i_logSize = 10;

    // calculate the max content size in bytes
    i_contentSize = i_logSize * 1024 * 1024;

    // set the max content size
    httpSetMaxContentLength(i_contentSize);

    // get information if indexPage is set in Config
    bool indexPageNotFound;
    string indexPage;
    indexPageNotFound = paCfgReadValue(getPath(CONFIG_REL_PATH) + "config", "httpServer", "indexPage", indexPage) == -1;
    if ( indexPageNotFound )
    {
      httpConnect("redirectToDownload", "/");
    }

    httpConnect("getIndex", "/download");
    httpConnect("workInfo", "/_info", "text/plain");

    //if serverSideAuth is enabled - set necessary permissions for _info URL
    if (isServerSideLoginEnabled)
    {
      bool bAllowUnknownUsers  = TRUE;
      bool bCheckPassword      = TRUE;
      bool bAllowDisabledUsers = FALSE;
      authServerSide.getHttpPermissions(bAllowUnknownUsers,bCheckPassword,bAllowDisabledUsers);
      httpSetPermission("/_info", makeMapping("allowUsers", "*",
                                              "allowUnknownUsers", bAllowUnknownUsers,
                                              "checkPassword", bCheckPassword,
                                              "allowDisabledUsers", bAllowDisabledUsers));

      // Allow the ULC UX
      mapping permission = makeMapping("allowUnknownUsers", TRUE, "allowDisabledUsers", TRUE);

      httpSetPermission("/data/ulc/*",     permission);
      httpSetPermission("/favicon.ico",    permission);
      httpSetPermission("/UI_LoadBalance", permission);
      httpSetPermission("/UI_WebSocket",   permission);

      httpSetPermission("/pictures/*",     permission);
    }

    // for security reasons, the config directory can not be accessed directly
    httpConnect("getConfig", "/config/config", "text/plain");
    httpConnect("getStyleSheet", "/config/stylesheet.css", "text/plain");
    httpConnect("getTouchStyleSheet", "/config/touchscreen.css", "text/plain");
    httpConnect("getHostCert", "/config/host-cert.pem", "text/plain");
    httpConnect("getHostKey", "/config/host-key.pem", "text/plain");
    httpConnect("getRootCert", "/config/root-cert.pem", "text/plain");
    // IM 119158 (cstoeg): get also powerconfig file
    httpConnect("getPowerConfig", "/config/powerconfig", "text/plain");
    httpConnect("logFileUpload", "/logFileUpload", "text/plain");


    // FMCS WEB SERVER
    FMCS_StartWebServer();


    dpQueryConnectSingle("cbConnectUI", TRUE, "connect", "SELECT '_online.._value' FROM '_Ui_*.DisplayName' WHERE _DPT= \"_Ui\" AND '_online.._value' != \"\" ");
    dpQueryConnectSingle("cbDisconnectUI", FALSE, "disconnect", "SELECT '_online.._value' FROM '_Ui_*.DisplayName' WHERE _DPT= \"_Ui\" AND '_online.._value' == \"\" ");
  }
  else
  {
    errClass err;
    err=makeError("", PRIO_WARNING, ERR_CONTROL, 54, "httpServer could not be started");
    throwError(err);
  }
}


//--------------------------------------------------------------------------------

dyn_string authInfo(const dyn_string &names, const dyn_string &values, const string &user, const string &ip, const dyn_string &headerNames, const dyn_string &headerValues, const int &connIdx) {
    mapping m = makeMapping("needAuth", ulcNeedAuth, "user",  user, "uid", getUserId(user));
    return jsonEncode(m);
}


//--------------------------------------------------------------------------------
// type ... rpm|tgz

string getFileVersion(string name, string type, int &maxServicePack, int &maxPatchNum,
                      string subdir = "", string arch = "*")
{
  // get the highest servicePack-patchNum combination
  maxServicePack = 0;
  maxPatchNum = 0;

  string fileName;

  // get the filename of the rpm file, which includes the patch number
  // parse the patch number from that filename
  string dir = PVSS_PATH + "/data/clsetup/" + subdir;  // the files must be in pvss_path !
  dyn_string files = getFileNames(dir, "WinCC_OA_" + VERSION + "-" + name + "-*." + arch + "." + type);

  if ( dynlen(files) == 0 )
    return "";

  for (int i = 1; i <= dynlen(files); i++)
  {
    int servicePack;
    int patchNumber;
    sscanf(files[i], "WinCC_OA_" + VERSION + "-" + name + "-%d-%d.", servicePack, patchNumber);

    if ( (i == 1) || (servicePack > maxServicePack) )
    {
      maxServicePack = servicePack;
      maxPatchNum = patchNumber;
      fileName = files[i];
    }
    else if ( (servicePack == maxServicePack) && (patchNumber > maxPatchNum) )
    {
      maxPatchNum = patchNumber;
      fileName = files[i];
    }
  }

  return fileName;
}

//--------------------------------------------------------------------------------

string getCodeMeterRpm()
{
  const string dir = PVSS_PATH + "/data/clsetup/";
  dyn_string files = getFileNames(dir, "CodeMeter-*.rpm");

  if ( dynlen(files) == 0 )
    return "";
  else if ( dynlen(files) == 1)
    return files[1];

  // can't make any assumptions about the naming scheme of CodeMeter installers,
  // so just return the most recent one
  string name;
  time newestTs;
  for (int i = 1; i <= dynlen(files); i++)
  {
    time ts = getFileModificationTime(dir + files[i]);
    if ( ts > newestTs )
    {
      name = files[i];
      newestTs = ts;
    }
  }

  return name;
}

//--------------------------------------------------------------------------------

string getCodeMeterDeb()
{
  const string dir = PVSS_PATH + "/data/clsetup/";
  dyn_string files = getFileNames(dir, "codemeter_*.deb");

  if ( dynlen(files) == 0 )
    return "";
  else if ( dynlen(files) == 1)
    return files[1];

  // can't make any assumptions about the naming scheme of CodeMeter installers,
  // so just return the most recent one
  string name;
  time newestTs;
  for (int i = 1; i <= dynlen(files); i++)
  {
    time ts = getFileModificationTime(dir + files[i]);
    if ( ts > newestTs )
    {
      name = files[i];
      newestTs = ts;
    }
  }

  return name;
}
//--------------------------------------------------------------------------------

dyn_string handleUlcLogin(const dyn_string &names, const dyn_string &values, const string &user)
{
  string filePath = getPath(DATA_REL_PATH, "ulc/login/index.html");

  if ( filePath != "" )
  {
    mapping lang;
    mapping json;
    string content;

    fileToString(filePath, content);

    dyn_string langStrings = makeDynString("login", "usernameEmptyText","passwordEmptyText","welcomeText","cancel", "invalidCreditentials");
    for (int i = 1; i <= dynlen(langStrings); i++) {
        lang[langStrings[i]] = getCatStr("http", langStrings[i]);
     }
    json["lang"] = lang;

    int thisMajor = getVersionInfo("major"), thisMinor = getVersionInfo("minor"), thisPatch = getVersionInfo("patch");
    json["productVersion"] = thisMajor + "." + thisMinor + " P" + thisPatch;

    strreplace(content, "{DATA}", jsonEncode(json));

    return makeDynString(content, "Status: 200 OK");
  }

  // return not found (should not happen)
  return makeDynString(NOT_FOUND, "Status: 404 Not Found");
}


//--------------------------------------------------------------------------------

dyn_string redirectToDownload()
{
    return makeDynString("", "Status: 301 Moved Permanently", "Location: /download");
}

//--------------------------------------------------------------------------------

dyn_string getIndex(dyn_string names, dyn_string values, string user, string ip,
                    dyn_string headerNames, dyn_string headerValues)
{
  string filePath = getPath(DATA_REL_PATH, "webclient_index.html");
  if ( filePath == "" )  // does not exist
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");

  string content;
  fileToString(filePath, content);

  // get the highest servicePack-patchNum combination
  int maxServicePack = 0;
  int maxPatchNum = 0;

  if ( getFileVersion("desktop-ui-rhel", "rpm", maxServicePack, maxPatchNum, "linux-rhel-x86_64/") == "" )
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");

  string RPM1="linux-rhel-x86_64/WinCC_OA_" + VERSION + "-desktop-ui-rhel-" + (string)maxServicePack + "-" + (string)maxPatchNum;
  string RPM2="linux-sles-x86_64/WinCC_OA_" + VERSION + "-desktop-ui-sles-" + (string)maxServicePack + "-" + (string)maxPatchNum;
  string codeMeterRpm=getCodeMeterRpm();
  string codeMeterDeb=getCodeMeterDeb();
  string RPM4="linux-debian-x86_64/WinCC_OA_" + VERSION + "." + (string)maxPatchNum + "-DesktopUI-debian";

  // the download buttons:
  string download;

  // check the OS of the client
  int idx = dynContains(headerNames, "User-Agent");
  if ( idx > 0 )
  {
    string os = strtolower(headerValues[idx]);
    if ( strpos(os, "linux") != -1)
    {
      download =

          "<div style='padding-top:220px;padding-left:30px;'>"
          "<div style='margin:8px;'>Desktop UI x86-64 ("
          "<a href=\"/data/clsetup/" + RPM1 + ".x86_64.rpm\";' title='Download Desktop UI for RHEL/CentOS x86-64\'>RHEL/CentOS</a> | "
          "<a href=\"/data/clsetup/" + RPM2 + ".x86_64.rpm\";' title='Download Desktop UI for SLES/OpenSuse x86-64\'>SLES/OpenSuse</a> | "
          "<a href=\"/data/clsetup/" + RPM4 + ".x86_64.deb\";' title='Download Desktop UI for Industrial OS\'>Industrial OS </a>) <br />"
          "</div><div style='margin:8px;'>CodeMeter License Tool ("
          "<a href=\"/data/clsetup/" + codeMeterDeb + "\";' title='Download CodeMeter License Tool for Industrial OS\'>Industrial OS </a> | "
          "<a href=\"/data/clsetup/" + codeMeterRpm + "\";' title='Download CodeMeter License Tool UI for RHEL/CentOS x86-64 and SLES/OpenSuse x86-64\'>RPM</a>"
           ")</div>"
           "</div>";

    }
    else if ( strpos(os, "windows") != -1 )
    {
      if ( patternMatch("*i?86*", os) ||     // browser is 32bit
           (strpos(os, "nt 5.1") != -1) )    // Windows XP is always 32bit
      {
        download =
          "<div style='padding-top:240px; text-align:center;'>"
            "32-Bit Systems are not supported"
          "</div>";
      }
      else if ( (strpos(os, "x64") != -1) || (strpos(os, "win64") != -1) || (strpos(os, "wow64") != -1))    // browser is 64bit
      {
              download =
                "<div style='padding-top:220px;padding-left:30px;'>"
                "<div style='margin:8px;'>Desktop UI ("
                "<a href=\"/data/clsetup/windows-64/WinCC_OA_Desktop_UI_" + VERSION + "-64.exe\" title='Download Desktop UI for Windows 64-bit\'>Windows 64-bit</a>"
                 ")</div>";
      }
      else // CPU unknown; let the user select
      {
            download =
                "<div style='padding-top:220px;padding-left:30px;'>"
                "<div style='margin:8px;'>Desktop UI (32 bit not supported | "
                "<a href=\"/data/clsetup/windows-64/WinCC_OA_Desktop_UI_" + VERSION + "-64.exe\" title='Download Desktop UI for Windows 64-bit\'>Windows 64-bit</a>"
                 "</div>";
      }
    }
  }
  if ( download == "" )  // no (matching) OS found; let the user choose
  {
  download=
          "<div style='padding-top:220px;padding-left:30px;'>"
          "<div style='margin:8px;'>Desktop UI ("
          "<a href=\"/data/clsetup/windows-64/WinCC_OA_Desktop_UI_" + VERSION + "-64.exe\" title='Download Desktop UI for Windows 64-bit\'>Windows 64-bit</a> | "
          "<a href=\"/data/clsetup/" + RPM1 + ".x86_64.rpm\";' title='Download Desktop UI for RHEL/CentOS x86-64\'>RHEL/CentOS</a> | "
          "<a href=\"/data/clsetup/" + RPM2 + ".x86_64.rpm\";' title='Download Desktop UI for SLES/OpenSuse x86-64\'>SLES/OpenSuse</a> | "
          "<a href=\"/data/clsetup/" + RPM4 + ".x86_64.deb\";' title='Download Desktop UI for Industrial OS\'>Industrial OS </a>) <br />"
          "</div><div style='margin:8px;'>CodeMeter License Tool ("
          "<a href=\"/data/clsetup/" + codeMeterDeb + "\";' title='Download CodeMeter License Tool for Industrial OS\'>IndustrialOS </a> | "
          "<a href=\"/data/clsetup/" + codeMeterRpm + "\";' title='Download CodeMeter License UI for RHEL/CentOS x86-64 and SLES/OpenSuse x84-64\'>RPM</a>"
           ")</div>"
           "</div>";
    }

  strreplace(content, "<%DOWNLOAD>", download);

  return makeDynString(content, "Status: 200 OK");
}

//--------------------------------------------------------------------------------

anytype workInfoClientUpdateCheck(const dyn_string &names, const dyn_string &values, const string &user, const string &ip,
                                  const dyn_string &headerNames, const dyn_string &headerValues, const int &connIdx)
{
  if ( dynlen(names) < 5 ||
       dynContains(names, "major") <= 0 ||
       dynContains(names, "minor") <= 0 ||
       dynContains(names, "patch") <= 0 ||
       dynContains(names, "arch") <= 0 )
    return makeDynString("", "Status: 400 Bad Request");

  //TODO: check if strings are really numerics
  string cliMajor = values[dynContains(names, "major")];
  string cliMinor = values[dynContains(names, "minor")];
  string cliPatch = values[dynContains(names, "patch")];
  string cliArch = values[dynContains(names, "arch")];

  int cliLang = httpGetLanguage(connIdx);

  int thisMajor = getVersionInfo("major"), thisMinor = getVersionInfo("minor"), thisPatch = getVersionInfo("patch");

  DebugFTN("HTTP", "Client", cliMajor, cliMinor, cliPatch, cliArch, cliLang);
  DebugFTN("HTTP", "Server", thisMajor, thisMinor, thisPatch);

  string content = "";
  mapping m = makeMapping("major", thisMajor,
                          "minor", thisMinor,
                          "patch", thisPatch);

  if ((string)thisMajor == cliMajor &&
      (string)thisMinor == cliMinor)
  {
    DebugFTN("HTTP", "Version matches");

    if (thisPatch <= ((int)cliPatch))
    {
      DebugFTN("HTTP", "Patchlevel is OK for connection");

      m["connect"] = "OK";
      content = jsonEncode(m);

      return makeDynString(content, "Status: 200 OK");
    }
    else
    {
      DebugFTN("HTTP", "newer patch available.");
      // return new patch
      if (cliArch == "windows-64")
      {
        m["patchURL"] = "/data/clsetup/windows-64/WinCC_OA_Desktop_UI_" + VERSION + "-64.exe";
      }
      else if (cliArch == "windows")
      {
        m["patchURL"] = "/data/clsetup/windows/WinCC_OA_Desktop_UI_" + VERSION + ".exe";
      }
      else
      {
        int checkServicepack=0, checkPatch=0;

        string fn="";
        string name=cliArch;
        strreplace(name, "linux-", "");
        strreplace(name, "-x86_64", "");
        name="desktop-ui-" + name;
        fn=getFileVersion(name, "rpm", checkServicepack, checkPatch, cliArch + "/");

        if (fn == "" ||
            checkServicepack != 0 ||
            checkPatch != thisPatch)
        {
          DebugFTN("HTTP", "no valid patch package found");
          m["infoText"] = getCatStr("http", "rtUiOutdatedNoNewer", cliLang);
          m["connect"] = "OK";
          m["patchURL"] = "/";
          content = jsonEncode(m);
          return makeDynString(content, "Status: 200 OK");
        }

        m["patchURL"] = "/data/clsetup/" + cliArch + "/" + fn;
      }

      DebugFTN("HTTP", "Found patch for architecture", m["patchURL"]);

      m["infoText"] = getCatStr("http", "rtUiOutdatedNewer", cliLang);
      m["connect"] = "OK";
      content = jsonEncode(m);
      return makeDynString(content, "Status: 200 OK");
    }
  }
  else
  {
    DebugFTN("HTTP", "Version does not match server");
    m["infoText"] = getCatStr("http", "rtUiNoMatch", cliLang);
    m["connect"] = "NOK";
    m["patchURL"] = "/";

    content = jsonEncode(m);
    return makeDynString(content, "Status: 200 OK");

  }

  return makeDynString("", "Status: 400 Bad Request");
}

//--------------------------------------------------------------------------------

anytype workInfoUiWebRuntimeVersion(const dyn_string &names, const dyn_string &values, const string &user, const string &ip,
                                    const dyn_string &headerNames, const dyn_string &headerValues)
{
  int thisMajor, thisMinor;
  sscanf(VERSION, "%d.%d", thisMajor, thisMinor);

  string arch = "*";    // architecture
  string type = "rpm";  // package type

  string current = values[1];  // currently installed version on client (or empty)
  int currentMajor = 0, currentMinor = 0;
  int currentServicePack = 0, currentPatchNum = 0;

  int i = strpos(current, "ui-webruntime");
  if ( i >= 0 )
  {
    sscanf(current, "WinCC_OA_%d.%d-ui-webruntime-%d-%d.%s",
           currentMajor, currentMinor,
           currentServicePack, currentPatchNum, arch);
  }
  else
  {
    // check for requested architecture if no rpm is already installed
    int idx = dynContains(names, "arch");
    if ( idx >= 1 )
      arch = values[idx];
  }

  string sub;  // special variation of uiWebRuntime, e.g. for ITC
  int idx = dynContains(names, "sub");
  if ( idx >= 1 )
    sub = values[idx];

  idx = dynContains(names, "type");  // package type
  if ( idx >= 1 )
    type = values[idx];

  // get the highest servicePack-patchNum combination
  int maxServicePack, maxPatchNum;

  string fileName = getFileVersion("ui-webruntime", type, maxServicePack, maxPatchNum, sub, arch);

  if ( fileName == "" )
    return "";

  // create sortable strings, e.g. "Ver_SP_PPP"
  string myVersion, clVersion;
  sprintf(myVersion, "%02d%02d_%02d_%03d", thisMajor, thisMinor, maxServicePack, maxPatchNum);
  sprintf(clVersion, "%02d%02d_%02d_%03d", currentMajor, currentMinor, currentServicePack, currentPatchNum);
  DebugFN("HTTP", "myVersion", myVersion, "clientVersion", clVersion);

  if ( myVersion > clVersion )
    return "/data/clsetup/" + sub + '/' + fileName;
  else
    return "";   // nothing to download
}

//--------------------------------------------------------------------------------

anytype workInfoUuid(const dyn_string &names, const dyn_string &values, const string &user, const string &ip,
                     const dyn_string &headerNames, const dyn_string &headerValues, const int &connIdx)
{
  // get Data - UUID
  int idx = dynContains(names, "uuid");
  string uuid;

  if ( idx >= 1 )
    uuid = values[idx];

  // get Data - Model
  idx = dynContains(names, "model");
  string model;

  if ( idx >= 1 )
    model = values[idx];

  //TFS 15236: ULC UX shall not be handeled at all by device management
  if(model == "ulc")
    return "";

  // get Data - Name
  idx = dynContains(names, "name");
  string sname;

  if ( idx >= 1 )
    sname = values[idx];

  // get Data - Width
  idx = dynContains(names, "w");
  int w;

  if ( idx >= 1 )
    w = (int)values[idx];

  // get Data - Height
  idx = dynContains(names, "h");
  int h;

  if ( idx >= 1 )
    h = (int)values[idx];


  idx = dynContains(headerNames, "User-Agent");
  string sAppVersion;

  //App Version
  if ( idx >= 1)
  {
    dyn_string dsTemp;

   dsTemp = strsplit(headerValues[idx]," ");
   sAppVersion = dsTemp[3];

  }

  int cliLang = httpGetLanguage(connIdx);

  // .... check uuid
  dyn_string dpDeviceNames;
  dyn_string dsUUID, dsArguments, dsDeviceClass;
  dyn_bool dbunlocked, dbAutoLogin;
  dyn_int diManagerNum;
  mapping data;
  int iDynIndex;

  //Get Device Data from Datapoint
  dpGetCache(MOBILE_UI_PRAEFIX_DP + ".DisplayName", dpDeviceNames,
             MOBILE_UI_PRAEFIX_DP + ".UUID", dsUUID,
             MOBILE_UI_PRAEFIX_DP + ".DeviceClass", dsDeviceClass,
             MOBILE_UI_PRAEFIX_DP + ".AutoLogin", dbAutoLogin,
             MOBILE_UI_PRAEFIX_DP + ".Unlocked", dbunlocked,
             MOBILE_UI_PRAEFIX_DP + ".ManagerNumber", diManagerNum);

  iDynIndex = dynContains(dsUUID, uuid);

  //Case: UUID does not exist
  if (iDynIndex < 1)
  {
    //create datapoint with UUID and model
    dyn_string dsDeviceClasses;
    string sDeviceClass = "";
    dyn_int diHeight, diWidth;
    bool bMobileAutoUnlock, bRuntimeAutoUnlock;
    float fRatioDevice = (float)w/(float)h, fRatioClass_wh, fRatioClass_hw;

    //create Mapping
    data["arguments"] = "";
    data["deviceClass"] = sDeviceClass;
    data["deviceLocked"] = TRUE;

    int iManNum = 0;
    if (model != "desktop")
    {
      // Find a new fixed UI manager number if not a Desktop UI has connected
      for (int i = iLowestAutoManNumMobileUI; iManNum == 0 && i < 255; i++)
      {
        if (dynContains(diManagerNum, i) == 0)
          iManNum = i;
      }

      if (iManNum == 0)
      {
        throwError(makeError("", PRIO_SEVERE, ERR_PARAM, 54,
                             getCatStr("http", "noManNumError", cliLang), sname, model));

        // return the error to the mobile UI
        data["deviceLocked"] = TRUE;
        data["reason"] = "noManNum";

        data["infoText"] = getCatStr("http", "noManNumInfo", cliLang);
        data["titleText"] = getCatStr("http", "noManNumTitle", cliLang);
        return jsonEncode(data);
      }
    }

    dpGet(MOBILE_UI_PRAEFIX_DP_2 + ".AutoValidationEnabled", bMobileAutoUnlock,
          MOBILE_UI_PRAEFIX_DP_2 + ".AutoRuntimeValidationEnabled", bRuntimeAutoUnlock,
          MOBILE_UI_PRAEFIX_DP_2 + ".Name", dsDeviceClasses,
          MOBILE_UI_PRAEFIX_DP_2 + ".Resolution.Width", diHeight,
          MOBILE_UI_PRAEFIX_DP_2 + ".Resolution.Height", diWidth);

    //Case: AutoUnlock is enabled
    if ( (bMobileAutoUnlock && model != "desktop") || (bRuntimeAutoUnlock && model == "desktop") )
    {
      data["deviceLocked"] = FALSE;

      if (model != "desktop")
      {
        data["arguments"] = "-num " + iManNum;

        if (dpExists("_Ui_" + iManNum) == FALSE)
        {
          int iRet;

          iRet = dpCreate("_Ui_" + iManNum, "_Ui");

          if (dynlen(getLastError()) > 0 || iRet)
          {
            throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54,
                                 "Could not perform auto unlock, because internal datapoint: _Ui_" + iManNum + " could not be created"));

            data["deviceLocked"] = TRUE;
          }
          else
            dpSet("_Ui_" + iManNum + ".UserName:_archive.._type", DPCONFIG_DEFAULTVALUE,
                  "_Ui_" + iManNum + ".UserName:_archive.._archive", TRUE);
        }
      }
    }

    // define DP elements
    dyn_string dsDpe = makeDynString(MOBILE_UI_PRAEFIX_DP + ".DisplayName",
                                     MOBILE_UI_PRAEFIX_DP + ".UUID",
                                     MOBILE_UI_PRAEFIX_DP + ".ProductModel",
                                     MOBILE_UI_PRAEFIX_DP + ".ManagerNumber",
                                     MOBILE_UI_PRAEFIX_DP + ".DeviceClass",
                                     MOBILE_UI_PRAEFIX_DP + ".Unlocked",
                                     MOBILE_UI_PRAEFIX_DP + ".AutoLogin",
                                     MOBILE_UI_PRAEFIX_DP + ".AppVersion");

    // define values for the DP elements
    dyn_anytype daValues = makeDynAnytype(sname,
                                          uuid,
                                          model,
                                          iManNum,
                                          sDeviceClass, // Deviceclass Vorschlag aufgrund der Hoehe und Breite
                                          !data["deviceLocked"],
                                          FALSE,
                                          sAppVersion);

    dpDynAppend(dsDpe, daValues);

    dpSet(MOBILE_UI_PRAEFIX_DP_2 + ".NewDevice", TRUE);
  }
  else
  {
    //Case: UUID already exists

    //Update App Version
    dyn_string dsDpe = makeDynString(MOBILE_UI_PRAEFIX_DP + ".AppVersion");
    dyn_anytype daValues = makeDynAnytype(sAppVersion);
    dpDynIdxSet(iDynIndex, dsDpe, daValues);

    //create Mapping - arguments, deviceclass, locked, rootpanel
    if (model != "desktop")
      data["arguments"] = "-num " + diManagerNum[iDynIndex];

    data["deviceClass"] = dsDeviceClass[iDynIndex];
    data["deviceLocked"] = !dbunlocked[iDynIndex];
  }

  return jsonEncode(data);
}

//--------------------------------------------------------------------------------

anytype workInfoSessionToken(const dyn_string &names, const dyn_string &values,
                             const string &user, const string &ip,
                             const dyn_string &headerNames, const dyn_string &headerValues, int connIdx)
{
  // Default return value is an empty session token
  string type = values[1];
  mapping data = makeMapping("sessionToken", "");
  string host = httpGetHeader(connIdx, "Host");

  if ( isServerSideLoginEnabled )
  {
    // Do not allow server side authentication over an unsecure connection
    if (!patternMatch("*:" + httpsPort, host))
    {
      throwError(makeError("", PRIO_SEVERE, ERR_PARAM, 54, "Server Side Authentication requires HTTPS"));

      anytype any;
      return any;
    }

    dyn_string error;
    OaAuthServerside auth;

    //if since last login the authentication method has changed the variable needs a new instance of an authServerside object
    if ( auth.getAuthType() != authServerSide.getAuthType() )
    {
      authServerSide = auth;
    }

    data = authServerSide.workInfoSessionToken(user, headerNames, headerValues, type, error);

    if (dynlen(error) > 0)
    {
      return error;
    }
  }

  return jsonEncode(data);
}

//--------------------------------------------------------------------------------
// return some information about the project

anytype workInfo(dyn_string names, dyn_string values, string user, string ip,
                 dyn_string headerNames, dyn_string headerValues, int connIdx)
{
  if ( dynlen(names) == 0 )
    return makeDynString("", "Status: 400 Bad Request");

  if ( names[1] == "projectName" )
  {
    string displayName;
    paCfgReadValue(getPath(CONFIG_REL_PATH) + "config", "general", "displayName", displayName);
    if ( displayName != "" )
      return displayName;
    else
      return PROJ + g_sProjExtension;
  }

  if ( names[1] == "wccoaVersion" )
    return VERSION;

  if ( names[1] == "serverTime" )
    return formatTimeUTC(values[1], getCurrentTime());

  if ( names[1] == "clientUpdateCheck" )
    return workInfoClientUpdateCheck(names, values, user, ip, headerNames, headerValues, connIdx);

  if ( names[1] == "uiWebRuntimeVersion" )
    return workInfoUiWebRuntimeVersion(names, values, user, ip, headerNames, headerValues);

  if ( names[1] == "uuid" )
    return workInfoUuid(names, values, user, ip, headerNames, headerValues, connIdx);

  if ( names[1] == "sessionToken" )
    return workInfoSessionToken(names, values, user, ip, headerNames, headerValues, connIdx);

  // retrieve a list of files /*and their last modified timestamp*/ (in XML format)
  // merged from all proj_paths

  // parameter 1: directory for recursive search or "|" separated list of directories for non recursively search
  // optional parameter 2: project names for searchleves to include; by default all search levels are included
  if ( names[1] == "listFiles" )
  {
    dyn_string files;
    if (!accessAllowed(values[1]))
    {
      throwError(makeError("_errors", PRIO_SEVERE, ERR_SYSTEM, 232, values[1]));
      return getCatStr("_errors", "00233");
    }
    DebugFTN(STDDBG_FILEOP, "WEBCLIENT", "names", names, "values", values);

    dyn_string dsDirectories = stringToDynString(values[1]);
    dyn_string dsSearchLevelFilter;

    if (dynlen(values) >= 2) // search only in special levels
      dsSearchLevelFilter = stringToDynString(values[2]);

    // INFO: Pattern match is done here in order to keep this "listFiles" feature generic
    files = getFileNamesLocal(dsDirectories, "*", dsSearchLevelFilter);

    int doc = xmlNewDocument();
    int root = xmlAppendChild(doc, -1, XML_ELEMENT_NODE, "fileList");

    for (int i = 1; i <= dynlen(files); i++)
    {
      if ( baseName(files[i][0]) == '.' )
        continue;  // hidden file, e.g. .colorDB.lock

      int node = xmlAppendChild(doc, root, XML_ELEMENT_NODE, "file");
      xmlSetElementAttribute(doc, node, "name", files[i]);

      /* TODO can be sent (if the file hierarchy-path is found) to speed up init
      xmlSetElementAttribute(doc, node, "lastModified",
          getFileModificationTime(PROJ_PATH + values[1] + "/" + files[i]));
      */
    }

    string strDoc = xmlDocumentToString(doc);
    xmlCloseDocument(doc);  // free memory
    DebugFN("HTTP", strDoc);
    return strDoc;
  }

  return makeDynString(NOT_FOUND, "Status: 404 Not Found");
}

//--------------------------------------------------------------------------------
// return the config file (a generated version containing already all config.* files,
// e.g. config.level, config.<OS>, config.redu

dyn_string getConfig(dyn_string names, dyn_string values, string user, string ip,
                     dyn_string headerNames, dyn_string headerValues)
{
  // Check if there is a special config file for the webclient
  string filePath = getPath(CONFIG_REL_PATH, "config.webclient");

  if ( filePath == "" )  // no, use normal config file
    filePath = getPath(CONFIG_REL_PATH, "config");

  string tmpConfig = tmpnam();
  if ( !copyFile(filePath, tmpConfig) )
  {
    throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54,
                         "Copying config-file " + filePath + " to temp-config-file " + tmpConfig + " not possible"));
    return makeDynString("", "Status: 500 Internal Server Error");  // Kopiervorgang ist schief gegangen
  }

  dyn_string dsProjPathes;
  paCfgReadValueList(tmpConfig, "general", "proj_path", dsProjPathes);
  for (int i = 1; i <= dynlen(dsProjPathes); i++)
    paCfgDeleteValue(tmpConfig, "general", "proj_path");

  // we add event to the config to be transferred to client
  dyn_string dsEvents, dsEventHost;
  paCfgReadValueList(tmpConfig, "general", "event", dsEvents);
  paCfgReadValueList(tmpConfig, "general", "eventHost", dsEventHost);

  if ( (0 == dynlen(dsEvents)) && (0 == dynlen(dsEventHost)) )
  {
    //we have only one event manager in this case (single system)
    dyn_string host = eventHost();
    string target = host[1] + ":" + eventPort();
    paCfgInsertValue(tmpConfig, "general", "event", target);
  }

  // we add data to the config to be transferred to client
  dyn_string dsDatas, dsDataHost;
  paCfgReadValueList(tmpConfig, "general", "data", dsDatas);
  paCfgReadValueList(tmpConfig, "general", "dataHost", dsDataHost);

  if ( (0 == dynlen(dsDatas)) && (0 == dynlen(dsDataHost)) )
  {
    //we have only one data manager in this case (single system)
    dyn_string host = dataHost();
    string target = host[1] + ":" + dataPort();
    paCfgInsertValue(tmpConfig, "general", "data", target);
  }

  string config;
  fileToString(tmpConfig, config);
  remove(tmpConfig);

  // from WinCC_OA install dir down to project dir
  dyn_string configFiles;
  dynAppend(configFiles, "config.level");

  // add the config.<OS> from the clients OS if possible
  int idx = dynContains(headerNames, "User-Agent");
  if ( idx > 0 )
  {
    string os = strtolower(headerValues[idx]);
    if ( strpos(os, "linux") != -1 )
      dynAppend(configFiles, "config.linux");
    else if ( strpos(os, "windows") != -1 )
      dynAppend(configFiles, "config.nt");
    else if ( strpos(os, "sunos") != -1 )
      dynAppend(configFiles, "config.solaris");
  }

  if ( isRedundant() )
    dynAppend(configFiles, "config.redu");

  for (int i = SEARCH_PATH_LEN; i >= 1; i--)
  {
    for (int j = 1; j <= dynlen(configFiles); j++)
    {
      filePath = getPath(CONFIG_REL_PATH, configFiles[j], 0, i);
      if ( filePath != "" )
      {
        string content;
        fileToString(filePath, content);
        config += "\n## " + filePath + " ##\n";
        config += content;
      }
    }
  }

  return makeDynString(config, "Status: 200 OK");
}

//--------------------------------------------------------------------------------
// read all stylesheet files from all proj-paths and return the merged contents

string getMergedStylesheets(const string &fileName)
{
  string mergedContents;

  for (int i = SEARCH_PATH_LEN; i >= 1; i--)
  {
    string filePath = getPath(CONFIG_REL_PATH, fileName, 0, i);
    if ( filePath != "" )
    {
      string contents;
      fileToString(filePath, contents);
      mergedContents += "\n/* " + filePath + " */\n";
      mergedContents += contents;
    }
  }

  return mergedContents;
}

//--------------------------------------------------------------------------------
// return the config/stylesheet.css file

dyn_string getStyleSheet()
{
  string contents = getMergedStylesheets("stylesheet.css");

  if ( contents == "" )
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");
  else
    return makeDynString(contents, "Status: 200 OK");
}

//--------------------------------------------------------------------------------
// IM 119158: return the config/powerconfig
dyn_string getPowerConfig()
{
  string contents = "";
  for (int i = 1; i <= SEARCH_PATH_LEN; i++) //search in Project first
  {
    string filePath = getPath(CONFIG_REL_PATH, "powerconfig", 0, i);
    if ( filePath != "" )
    {
      contents = "";
      bool ret;
      ret = fileToString(filePath, contents);
      if( ret != 0 && contents != "" ) //jump out if a powerconfig file is found
        break;
    }
  }

  if ( contents == "" )
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");
  else
    return makeDynString(contents, "Status: 200 OK");
}

//--------------------------------------------------------------------------------
// upload the sent logfile from mobile app
void logFileUpload(blob content, string user, string ip, dyn_string headernames, dyn_string headervalues, int connIdx)
{
  int index;
  index = dynContains(headernames, "X-UUID");
  if ( index > 0 )
  {
    // found UUID in header
    string uuid = headervalues[index];

    dyn_string dsUUID;
    dyn_bool dbUnlocked;
    dyn_int diManagerNumbers;
    dyn_string dsDisplayNames;
    dpGetCache(MOBILE_UI_PRAEFIX_DP + ".UUID", dsUUID,
               MOBILE_UI_PRAEFIX_DP + ".Unlocked", dbUnlocked,
               MOBILE_UI_PRAEFIX_DP + ".ManagerNumber", diManagerNumbers,
               MOBILE_UI_PRAEFIX_DP + ".DisplayName", dsDisplayNames);

    index = dynContains(dsUUID, uuid);
    if ( index > 0 )
    {
      // UUID exists
      if ( dbUnlocked[index] )
      {
        // OK - save logfiles
        string contentType = httpGetHeader(connIdx, "Content-Type");
        int pos = strpos(contentType, "boundary=");
        if (pos >= 0)
        {
          string boundary = substr(contentType, pos + 9);

          // Hochkomma (") am Beginn und Ende entfernen
          boundary = substr(boundary, 1);
          boundary = substr(boundary, 0, strlen(boundary) - 1);

          mapping result;
          string saveDir = "";
          if ( diManagerNumbers[index] == 0 )  // desktop --> ManNr. 0
            saveDir = PROJ_PATH + LOG_REL_PATH + "desktopUI_logs_ui" + dsDisplayNames[index] + "/";
          else
            saveDir = PROJ_PATH + LOG_REL_PATH + "mobileUI_logs_ui" + diManagerNumbers[index] + "/";
          mkdir(saveDir);
          int retval = httpSaveFilesFromUpload(content, boundary, saveDir, result);
        }
      }
      else
        throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54,
                             "Your device needs to be authorized - logfiles not accepted!"));
    }
    else
      throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54,
                           "UUID does not exist - UUID invalid - logfiles not accepted!"));
  }
}

//--------------------------------------------------------------------------------
// return the config/touchscreen.css file

dyn_string getTouchStyleSheet()
{
  string contents = getMergedStylesheets("touchscreen.css");

  if ( contents == "" )
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");
  else
    return makeDynString(contents, "Status: 200 OK");
}

//--------------------------------------------------------------------------------
// return the config/host-cert.pem file

dyn_string getHostCert(dyn_string names, dyn_string values, string user, string ip,
                       dyn_string headerNames, dyn_string headerValues)
{
  return getFile(names, values, user, ip, headerNames, headerValues, "host-cert.pem", CONFIG_REL_PATH);
}

//--------------------------------------------------------------------------------
// return the config/host-key.pem file

dyn_string getHostKey(dyn_string names, dyn_string values, string user, string ip,
                      dyn_string headerNames, dyn_string headerValues)
{
  return getFile(names, values, user, ip, headerNames, headerValues, "host-key.pem", CONFIG_REL_PATH);
}

//--------------------------------------------------------------------------------
// return the config/root-cert.pemfile

dyn_string getRootCert(dyn_string names, dyn_string values, string user, string ip,
                       dyn_string headerNames, dyn_string headerValues)
{
  return getFile(names, values, user, ip, headerNames, headerValues, "root-cert.pem", CONFIG_REL_PATH);
}

//--------------------------------------------------------------------------------
// return the file fileName

dyn_string getFile(dyn_string names, dyn_string values, string user, string ip,
                   dyn_string headerNames, dyn_string headerValues, string fileName, string subPath = "")
{
  string filePath = getPath(subPath, fileName);
  if ( filePath == "" )  // does not exist
    return makeDynString(NOT_FOUND, "Status: 404 Not Found");

  time m = getFileModificationTime(filePath);

  int idx = dynContains(headerNames, "If-Modified-Since");
  if ( idx > 0 )
  {
    time t = httpParseDate(headerValues[idx]);

    // to be able to have the exact same file on the client as on the server,
    // compare times as equal
    if ( m == t )
      return makeDynString("", "Status: 304 Not Modified");
  }

  string config;
  fileToString(filePath, config);
  return makeDynString(config, "Status: 200 OK", "Last-Modified: " + formatTime("HTTP", m));
}

//--------------------------------------------------------------------------------

void cbConnectUI(anytype atUserData, dyn_dyn_anytype ddaQRes)
{
  dyn_bool unlocked;
  dyn_string dsUUIDs;
  dpGet("_UiDevices.Unlocked", unlocked,
        "_UiDevices.UUID", dsUUIDs);

  for(int i = 2; i <= dynlen(ddaQRes); i++)
  {
    mapping mTemp = jsonDecode(ddaQRes[i][2]);
    if ( mappingHasKey(mTemp, "id") )
    {
      string uuid;
      int uiManNum;
      uuid = mTemp["id"];
      sscanf(dpSubStr(ddaQRes[i][1], DPSUB_DP), "_Ui_%d", uiManNum);

      if ( !mappingHasKey(mUiUuid, uiManNum) )
        mUiUuid[uiManNum] = uuid;

      int pos = dynContains(dsUUIDs, uuid);
      if ( pos > 0 )
      {
        if ( unlocked[pos] == FALSE )
        {
          int iManID = convManIdToInt(UI_MAN, uiManNum);

          if ( isRedundant() )
            dpSet("_Managers.Exit", iManID, "_Managers_2.Exit", iManID);
          else
            dpSet("_Managers.Exit", iManID);
        }
      }
    }
  }
}

//--------------------------------------------------------------------------------

void cbDisconnectUI(anytype atUserData, dyn_dyn_anytype ddaQRes)
{
  for(int i = 2; i <= dynlen(ddaQRes); i++)
  {
    int uiManNum;
    sscanf(dpSubStr(ddaQRes[i][1], DPSUB_DP), "_Ui_%d", uiManNum);

    if ( mappingHasKey(mUiUuid, uiManNum) )
      mappingRemove(mUiUuid, uiManNum);
  }
}

//--------------------------------------------------------------------------------
/**
  @author jhercher
  callback function handling UI Managers connecting and disconnecting
*/
void cbHandleUiConnections(string dp1, dyn_int connectedUIs1, string dp2, dyn_int connectedUIs2)
{
  dynAppend(connectedUIs1, connectedUIs2);
  dynUnique(connectedUIs1);

  authServerSide.handleConnections(connectedUIs1);
}

//--------------------------------------------------------------------------------
/**
  @author jhercher
  callback function handling Sessiontoken written to _System.Auth.SessionTokenInterface
  this callback function must only be executed by one webserver! This is especially true on a redu system where only
  the webclient from the active system must execute this or changes to the session tokens might be lost.
*/

void cbHandleSessionTokens(string dp, string token)
{
  string prefix = token[0];
  token = substr(token, 1);

  authServerSide.handleSessionTokens(prefix, token);
}

//--------------------------------------------------------------------------------
/**
  @author jhercher
  function parses infoList path to see if unallowed path traversel happens
  @param path: path to be parsed
  @return bool: if path contains .. indicating parentdirectory the function returns TRUE else FALSE
  */

bool accessAllowed(string path)
{
  strreplace(path, "\\", "/");
  dyn_string pathTokens = stringToDynString(path, "/");
  int sum = 0;

  for (int i = 1; i <= dynlen(pathTokens); i++)
  {
    int len = strlen(pathTokens[i]);
    if (pathTokens[i] == "..")
    {
      sum--;
    }
    else if (len > 0 && pathTokens[i] != ".")
    {
      sum++;
    }
    if (sum < 0)
    {
      return FALSE;
    }
  }

  return TRUE;
}

//--------------------------------------------------------------------------------
