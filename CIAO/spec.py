# http://cxc.harvard.edu/sherpa4.10/threads/sourceandbg/
from sherpa_contrib.all import *
from sherpa.astro.ui import *
from ciao_contrib.runtool import *
from pychips import *
import astropy.io.ascii as at
import numpy as np
from functions import *

a=at.read("cluster.txt")
a['z'][0]=0.182
load_pha(1,"spec/source.pi")

subtract()
notice(0.6,9)
norm = a['bkg_norm'][0]
A = 1
if norm<0:
  A = -1
# Modelos
set_source(xsphabs.abs1*xsapec.p1+A*xsphabs.abs1*xsapec.bg)

# Parametros inciais
Zsun=0.0134
abs1.nH = 0.07
p1.redshift = a['z'][0]
bg.norm, bg.kT, bg.Abundanc, bg.redshift = abs(norm), 0.18, Zsun, 0

thaw(p1)
freeze(bg,)
freeze(abs1.nH, p1.redshift)
show_model()
# Primeiro Ajuste
# fit()
# covar()
# fitr = get_fit_results()
# covr = get_covar_results()
# mylist = [[fitr.parvals[0],covr.parmaxes[0]]]
# # Segundo Ajuste
# for i in range(2):
#     sigma = a['errbkg_norm']*(-1)**(i)
#     bg.norm = norm+sigma
#     fit()
#     covar()
#     fitr = get_fit_results()
#     mylist.append([fitr.parvals[0],covr.parmaxes])
#
# T = np.array(mylist)
# a['kT'] = np.mean(T[:,0])
# # O erro é estimado, como a variância em T mais a média de sigma²
# a['ErrkT'] = (np.std(T[:,0])**2+np.mean(T[:,1]**2))**(0.5)
#
# plot_fit_delchi()
# print_window("fit_spectrum.png", {"clobber":True})

# flux = calc_energy_flux()

# Relação Massa-Temperatura Vikhlinin et al. 2006
T5=5; M5=2.89*1e14; r5=0.792;
# --->Temperatura em keV, Massa em massas solares, e r5 em Mpc
alpha=1.58
kT = a['kT'][0]
z_cls = 0.182
DA = (cosmo.luminosity_distance(z_cls)/(1+z_cls)**2)/u.Mpc
DA = float(1e+3*DA) # em kpc
A = 1/float(h*E(z_cls))
r500_TM = A*r5*(kT/T5)**(alpha/3) # em kpc
M_TM = M5*(kT/T5)**(alpha)

r500_PHY = r_kpc_theta(r500_TM)/pixscale

a['r500_PHY'] = r500_PHY

at.write(a,"cluster.txt",overwrite=True)
