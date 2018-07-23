import astropy.io.ascii as at
from ciao_contrib.runtool import *
import numpy as np

#--- Carregando tabelas
clt = at.read("cluster.txt")
obsid="00"+str(clt["obsid"][0])
pixscale=clt["pixscale"][0]

# arquivo de eventos filtrado por flares e sem fontes pontuais
evtge="ps_excl_evt.fits"

t500=200
ri, rfim = 0.1*t500, 1.5*t500,
naneis = int( np.log((rfim/ri) -1)/np.log(1.05))

rbin = [50*(1.05)**(i+1) for i in range(naneis)]

saida = "aneis.reg"
with open(saida,"w") as file:
    for i in range(naneis-1):
        file.write("annulus("+str(clt["xcen"][0])+","+str(clt["ycen"][0])+","+str(rbin[i])+","+str(rbin[i+1])+") \n")

rbkg=rfim+50
with open("bkg_"+saida,"w") as file:
        file.write("annulus("+str(clt["xcen"][0])+","+str(clt["ycen"][0])+","+str(rfim)+","+str(rbkg)+")\n")

dmextract.punlearn()
dmextract.infile = evtg+"[bin sky=@"+saida+"]"
dmextract.outfile = obsid+"_rprofile.fits"
dmextract.bkg = evtge+"[bin sky=@bkg_"+saida+"]"
dmextract.exp = "00524_0.7-2_thresh.expmap"
dmextract.bkgexp = "00524_0.7-2_thresh.expmap"
dmextract.opt = "generic"
dmextract()

dmtcalc.punlearn()
dmtcalc.infile= obsid+"_rprofile.fits"
dmtcalc.outfile=obsid+"_rprofile_rmid.fits"
dmtcalc.expression="rmid=0.5*(R[0]+R[1])"
dmtcalc()

dmstat(obsid+"_rprofile_rmid.fits[col COUNTS]", clip=True, nsigma=2)
smin=str(dmstat.out_min)
smax=str(dmstat.out_max)

dmcopy("00524_rprofile_rmid.fits[COUNTS="+smin+":"+smax+"]","filtro.fits")
dmstat("filtro.fits[col RMID]", clip=False)
rmax=float(dmstat.out_mean)
rsgm=float(dmstat.out_sigma)

dmlist filtro.fits'[cols R, SUR_FLUX]' data
