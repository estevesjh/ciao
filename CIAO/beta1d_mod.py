from scipy.integrate import quad
import numpy as np

# Definindo funções
# pars[0],pars[1],pars[2],pars[3],pars[4],pars[5],pars[6] = rc,rs,a,b,e,g,n0
# Código feito em 15 de Junho de 2018

# Definindo funções

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
        aux=quad(integral,R,np.inf,args=(R,rc,rs,a,b,e,g,n0),epsabs=1e-10)
        res=aux[0]
        out.append(res)
    return out

# SBV = np.vectorize(Eprojected)


#par0 = [80,400,0.5,1.0,1.0,3,0.0210105]

#Eprojected(par0,100)
