import astropy.io.ascii as at
import astropy.units as u
from astropy.cosmology import FlatLambdaCDM
from scipy.optimize import minimize, rosen, rosen_der
from scipy.integrate import quad
import numpy as np
from sympy import *
# from beta1d_mod import*
# from functions import *
# pip.main(['install','sympy','--user'])

#--- cosmologia
h = 0.7
cosmo = FlatLambdaCDM(H0=h*100, Om0=0.3)

# Unidades em cgs
mp = 1.67262e-24; G = 6.67408e-8; Msol = 1.98847e33; AU=1.495978707e13; pc=3.085677581467192e+18; keV = 1.6e-8

# Precisa se definir anteriormente as seguintes variaveis
# kT, rho_critico, DA

# Funções básicas

#--- Conversão de distância física para Mpc
def r_phy_kpc(r_phy):
    theta = r_phy*pixscale # em arcsec
    res = theta*DA*AU/pc
    return res*1e+3 # em kpc
def r_kpc_theta(r_kpc):
    res = 1e-3*(r_kpc/DA)*(pc/AU)
    return res
#--- Função da evolução do redshift
def E(z):
    res = cosmo.H(z)/cosmo.H(0)
    return res
#--- Perfil de Temperatura
def T(r,r500):
    x = r/r500
    B = 1/(1+(x/0.6)**(2))**(0.45)
    C = 1/((x/0.045)**(1.9)+1)
    res = 1.1*1.35*((x/0.045)**(1.9)+0.45)*B*C
    return res
def npne(r,rc,rs,a,b,e,n0):
    g = 3
    A = (n0**2)*(r/rc)**(-a)
    B = 1/(1+(r/rs)**(g))**(e/g)
    res = A*B/(1+(r/rc)**2)**(3*b-a/2)
    return res
def rhogas(r,rc,rs,a,b,e,n0):
    res = 1.6*mp*(npne(r,rc,rs,a,b,e,n0))**(0.5)
    return res
def M(r,rc,rs,a,b,e,n0):
    kT=4*keV; g=3
    x_cm = r*1e3*pc
    A = -kT*x_cm*r/(G*0.6*mp)/Msol
    # Derivada do log rhogas
    B = -0.5*( (a*rc**2 + 6*b*r**2)/(r**3 + r*rc**2) + (
 e*r**2)/(r**3 + rs**3) )
    # A = 1
    res = A*B*1e-14
    return res
def M500(r,z_agl):
    delta = 500
    rhoc = float(((3*cosmo.H(z_agl)**2/(8*np.pi*G)).cgs)*u.s**2)
    x_cm3 = (r*1e3*pc)**3
    res = 1e-14*delta*(4*np.pi/3)*rhoc*x_cm3/Msol
    # print(res/x_cm3)
    return res
def func(x,rc,rs,a,b,e,n0,z_agl):
    res = M(x,rc,rs,a,b,e,n0) - M500(x,z_agl)
    return res
def rdelta(r500_0,rc,rs,a,b,e,n0,z_agl):
    delta=500
    r500vec = np.arange(0.5*r500_0,1.5*r500_0,r500_0/100)
    aux = func(r500vec,rc,rs,a,b,e,n0,z_agl)
    # aux = minimize(func, r500_0, args=(rc,rs,a,b,e,n0,z_agl),method='Nelder-Mead')
    return aux
# def rho(r,rc,rs,a,b,e,n0):
#     A = diff(M(r,rc,rs,a,b,e,n0),r)
#     res = A/(4*np.pi*r**2)
#     return res
# Definindo funções de ajuste beta modificado
def integral(r,R,rc,rs,a,b,e,g,n0):
    beta=(n0**2)*((r/rc)**(-a))/( (1+(r/rc)**(2))**(3*b-a/2) )
    res1 = beta/( 1+(r/rs)**(g) )**(e/g)
    res = 2*res1*r/(r*r-R*R)**(1/2)
    return res
def Eprojected(pars,x):
    (rc,rs,a,b,e,g,n0) = pars
    out = []
    for i in range(len(x)):
        R = x[i]
        aux=quad(integral,R,np.inf,args=(R,rc,rs,a,b,e,g,n0),epsabs=1e-20)
        res=aux[0]
        out.append(res)
    return out
