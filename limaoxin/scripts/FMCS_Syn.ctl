main()
{
syn();
}


syn()
{
  dyn_dyn_anytype tab;
  dyn_string st;
  string  query;
  string dpe,ds;
  dyn_string core,da;
  dyn_anytype value;
  query = "SELECT '_original.._value'";
  query += "FROM 'F3P1*'";
  query += "REMOTE 'CORE:'";
  dpQuery(query,tab);
  for (int i = 1; i <= dynlen(tab)-1; i++)
  {
    st = strsplit(tab[i+1][1]," ");
    core[i]=st[1];
    da[i]=st[1];
    uniStrReplace(da[i],"CORE:","DA1:");
  }


  while(1)
  {
    dpGet(da,value);
    dpSet(core,value);
    delay(3);

  }
}
