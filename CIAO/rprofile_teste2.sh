
pset specextract infile ="${evtc}[sky=@aneis.reg]"
pset specextract outroot=spec/anel
pset specextract bkgfile="${obsid}_blank.evt[sky=@aneis.reg]"
pset specextract grouptype=NUM_CTS
pset specextract binspec=50
specextract mode=h
