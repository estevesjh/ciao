from astropy.io import fits
from functions import *
from ciao_contrib.runtool import *
import sys

# obsid = sys.argv[0]
# kT = sys.argv[1]
# r500 = sys.argv[2]

a=at.read("cluster.txt")

obsid = str(a["obsid"][0])
# 0.3 Conversão de counts para fluxo

# Carregando Tabela Fits
hdul = fits.open(str(obsid)+"_rprofile_rmid_source.fits")
data = hdul[1].data
cols = hdul[1].columns

et1 = at.read("lista.arf")
et2 = at.read("lista.rmf")

arf = et1.colnames
rmf = et2.colnames

# Definindo variaveis
a['z'][0] = 0.182
pixscale = a['pixscale'][0]
kT = a['kT'][0]
rbin = data['rmid']

mylist = []
for i in range(len(rbin)):
    modelflux(arf=arf[i], rmf=rmf[i], model="xsphabs.abs1*xsapec.p1", paramvals="abs1.nh=0.07;p1.kT="+str(kT*T(rbin[i],r500_PHY))+";p1.Abundanc=0;p1.norm=1", emin=0.7, emax=2)
    mylist.append(modelflux.flux)

flux_conv = np.array(mylist)

col = ['COUNT_RATE','COUNT_RATE_ERR','BG_RATE','BG_SUR_BRI','BG_SUR_BRI_ERR','NET_RATE','ERR_RATE','SUR_BRI','SUR_BRI_ERR']
for i in range(len(col)):
    data[col[i]] = flux_conv*data[col[i]]
nmin = np.min(data['NET_RATE'])
data['NET_RATE'] = data['NET_RATE']-nmin
data['NET_RATE'] = data['NET_RATE']/abs(nmin)
data["ERR_RATE"] = data["ERR_RATE"]/abs(nmin)

data["RMID"] = r_phy_kpc(data["RMID"])

hdul.writeto('SB_flux.fits',overwrite=True)
