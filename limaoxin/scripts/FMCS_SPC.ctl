#uses "CtrlHTTP"
#uses "FMCSLibs/SPC"

main()
{
  httpServer(0,80,0);
  SPC_WebReporting();
}
