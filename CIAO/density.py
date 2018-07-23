# Esse código ajusta um perfil beta modificado
# Criado em 26 de Junho de 2018
from sherpa_contrib.all import *
from sherpa.astro.ui import *
from ciao_contrib.runtool import *
from pychips import *
from astropy.io import fits
import astropy.io.ascii as at
import sys
from functions import *
import matplotlib.pyplot as plt

z_cls = 0.182
par0 = [14.0947,239.625,9.66641e-06,0.450961,1.17144,3.0,0.00975581]
rc0, rs0, alpha0, beta0, gamma0, ep0, n00 = par0
r500_in = 800

# Teste das funções Massa
# O ponto de encontro é R500
x = np.arange(10,1500,10)
y1 = M(x,150,1100,alpha0,beta0,ep0,n00)
y2 = M500(x,z_cls)
plt.plot(x,y1,'b',x,y2)

# obsid = sys.argv[1]

# Unidades em cgs
mp = 1.67262e-24; G = 6.67408e-8; Msol = 1.98847e33; AU=1.495978707e13; pc=3.085677581467192e+18

#--- cosmologia
h = 0.7
cosmo = FlatLambdaCDM(H0=h*100, Om0=0.3)

#---- Carregando Dados
a=at.read("cluster.txt")

obsid = str(a['obsid'][0])
# Carregando Tabela Fits
hdul = fits.open(obsid+"_rprofile_rmid_source.fits")
data = hdul[1].data
cols = hdul[1].columns

# Definindo variaveis
z_cls = a['z'][0]
pixscale = a['pixscale'][0]
kT = a['kT'][0]
rhoc = 3*cosmo.H(z_cls)**2/(8*np.pi)
DA = (cosmo.luminosity_distance(z_cls)/(1+z_cls)**2)/u.Mpc
DA = float(DA) # em Mpc

load_data(1,'SB_flux.fits', 3, ["RMID","NET_RATE","ERR_RATE"])

pars = ["rc","rs","alpha","beta","epsilon","gamma","n0"]
load_user_model(Eprojected,"mybeta")
par0 = [14.0947,0.492*239.625,9.66641e-06,0.450961,1.17144,3.0,0.0975581]
frzpar=5*[False]+[True,False]

add_user_pars("mybeta", pars, par0, parfrozen=frzpar)
set_model("mybeta")

mybeta.rc.min = 0
mybeta.rc.max = 1e6
mybeta.rs.min = 1e-6
mybeta.rs.max = 1e6
mybeta.alpha.min = 1e-5
mybeta.alpha.max = 1e2
mybeta.beta.min = 0
mybeta.beta.max = 1e2
mybeta.epsilon.min = 0
mybeta.epsilon.max = (5-1e-3)
mybeta.gamma.min = 1e-5
mybeta.n0.min = 0
freeze(mybeta)
show_model()
fit()
fitr = get_fit_results()
plot_fit_delchi()

out = np.array(fitr.parvals)
out[0] = out[0]*pixscale

print(out)
at.write(out, "beta1d.txt", names=fitr.parnames)

### Encontrando R500
