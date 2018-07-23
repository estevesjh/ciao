import astropy.io.ascii as at
from scipy import optimize
import scipy.special as sp
import numpy as np
import astropy.units as u
from astropy.constants import M_sun,G,m_p,e
from astropy.cosmology import FlatLambdaCDM
#! Confirmar unidades de rc
# Unidades em cgs
mp = 1.67262e-24; G = 6.67408e-8; Msol = 1.98847e33

#--- cosmologia
h = 0.7
cosmo = FlatLambdaCDM(H0=h*100, Om0=0.3)

#--- Massa Molecular Média
mu = 0.6

#--- Carregando tabelas
clt = at.read("cluster.txt")
beta2d = at.read("beta2d.txt")
spec = at.read("spec.txt")

saida = "output.txt"

#--- Cluster
z = float(clt["z"][0]) # redshift
pixscale = clt["pixscale"][0]
pixscale = 0.492

#--- Distância Angular
DA = (cosmo.luminosity_distance(z)/(1+z)**2).cgs
R_spec = (300)/pixscale  # raio projetado em unidades físicas
r_spec = ((300/3600)*(np.pi/180)*DA).to('kpc') # raio projetado em kpc

#--- Parametros: Modelo Beta
alpha = beta2d["ext.alpha"][0]
rc = beta2d["ext.r0"][0]     # Qual unidade?
beta = (alpha+0.5)/3

rc_kpc = ((rc*pixscale/3600)*(np.pi/180)*DA).to('kpc')

#--- APEC - espectro parâmetros
A = 1e14*float(spec["norm"][0])/(u.cm)**5
EI = A*(4*np.pi*DA*(1+z))**2
kT = (spec["kT"][0]*u.keV).cgs/u.erg

#### Definindo Funções
#--- Função da evolução do redshift
def E(z):
    res = cosmo.H(z)/cosmo.H(0)
    return res
#--- Função Hipergeometrica
def F1(r):
    a=(3/2); b=(3/2)*beta; c=(5/2);
    d=-float((r/rc_kpc)**2)
    I=sp.hyp2f1(a, b, c, d)
    return I

#--- Massa do Gás em função do raio
def mgas(r):
    res = (4*np.pi/3)*n0*mu*mp*F1(r)*(r.cgs)**3
    mgas = float(res/Msol)
    return mgas/1e13

#--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
#--- --- ------ --- --- Equilibrio Hidroestático --- --- --- --- --- ---
# Assumindo um perfil beta
DELTA = 500
rho_c = float(cosmo.critical_density(z)/(u.g/u.cm**3))

A = 4*np.pi*DELTA*rho_c*(G*mp*mu)
rc = float(rc_kpc.cgs/u.cm)
#---- Formula Analítica de R500 para um perfil beta
R500 = float((9*kT*beta/A-rc**2)**(0.5)) # em cm
M500 = (DELTA*rho_c*(4*np.pi/3)*R500**3)

# Definindo Dimensões
R500 = (u.cm*R500).to('kpc')
M500 = (M500/Msol)*1e-14

#--- Calculando n0
V_spec = (4*np.pi*(r_spec).cgs**3/3)
n0 = (EI/(V_spec*F1(r_spec)))**(0.5)
print(n0)

#--- Calculando Mg no R500
Mg500 = mgas(R500) # R500 em kpc, outuput em 1e13*Msolares

#--- Calculando Yx
Yx = 1e13*Mg500*spec["kT"][0]

#--- Calculando Masso do Halo (relação de escala) Kratsov et al. 2005
AYM=5.77/(h*(0.5))
BYM=0.57
CYM=3*1e14
M500_s = (E(z))**(-2/5)*AYM*(Yx/CYM)**(BYM) # em 10e14*Msolares

#--- Calculando Luminosidade
DL = float((DA/u.cm)*(1+z)**2)
Lx = spec["Flux"]*(4*np.pi*DL**2)/1e44

with open(saida, "w") as file:
    file.write("Obsid,Xcen,Ycen,redshift,R500,M500,Mg500,kT,Z,Lx \n")
    file.write("%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.5f,%.2f \n"%(clt["obsid"][0],clt["xcen"][0],clt["ycen"][0],z,float(R500/u.kpc),M500,Mg500,spec["kT"][0],spec["Abundance"][0],Lx))
