# http://cxc.harvard.edu/sherpa4.10/threads/sourceandbg/
from sherpa_contrib.all import *
from sherpa.astro.ui import *
from ciao_contrib.runtool import *
from pychips import *
import astropy.io.ascii as at
import numpy as np
import sys

print("====================Esse código ajusta o Bakcground====================")
print("Como usar: python fite.py [Tfit]")
Tfit = int(sys.argv[1])

if Tfit:
    print("Tfit=1; fitando a temperatura")
else:
    print("Tfit="+str(Tfit)+"; temperatura bkg fixa em 0.18keV")
a=at.read("cluster.txt")
# Normalizando o background
load_pha(1,"spec/bkg.pi")

rate_source = calc_data_sum(9.5,12,id=1)/get_exposure(id=1)
rate_bkg = calc_data_sum(9.5,12,bkg_id=1)/get_exposure(bkg_id=1)
bkg_scale = rate_source/rate_bkg


calc = "COUNTS=(COUNTS*"+str(bkg_scale)+"), COUNT_RATE=(COUNT_RATE*"+str(bkg_scale)+")"

dmtcalc.punlearn()
dmtcalc.infile = "spec/source_bkg.pi"
dmtcalc.outfile = "spec/source_bkg.pi"
dmtcalc.expression = calc
dmtcalc.clob = "yes"
dmtcalc()

rate_source2 = calc_data_sum(0.1,2.0,id=1)/get_exposure(id=1)
rate_bkg2 = calc_data_sum(0.1,2.0,bkg_id=1)/get_exposure(bkg_id=1)
bkg_scale2 = rate_source2/rate_bkg2

print("bkg_scale2:"+str(bkg_scale2))
# Ajustando o Bakcground

load_pha(1,"spec/bkg.pi")

# ---> 2 Ajuste Espectral
notice(0.01,2.0)
subtract()
A=1
if bkg_scale2>1:
    A = -1
set_model(A*xsphabs.abs1*xsapec.p1)

# group_counts(50)
Zsun=0.0134
abs1.nH = 0.07
p1.redshift, p1.kT, p1.Abundanc = 0, 0.18, Zsun
freeze(abs1.nH, p1)
thaw(p1.norm)
if Tfit:
    thaw(p1.kT)
show_model()

fit()
fitr = get_fit_results()

covar()
sigma = get_covar_results()

plot_fit_delchi()
print_window("fit_bkg.png", {"clobber":True})

if Tfit:
    a["bkg_kT"] = fitr.parvals[0]
    a["Errbkg_kT"] = sigma.parmaxes[0]

    a["bkg_norm"] = A*fitr.parvals[1]
    a["Errbkg_norm"] = sigma.parmaxes[1]
else:
    a["bkg_norm"] = A*fitr.parvals[0]
    a["Errbkg_norm"] = sigma.parmaxes[0]

at.write(a, "cluster.txt",overwrite=True)

# ---> 4. Gráfico
load_pha(1,"spec/bkg.pi")
# ---> 4.00 Binando em contagens"
group_snr(5)
group_snr(10,bkg_id=1)

# ---> 4.01 Definindo intervalo de energia"
notice(0.1, 12.5)

# ---> 4.1 Gráfico do Background da observação
plot_data()

# ---> 4.2 Definindo preferências no grafico
set_plot_xlabel("channel energy (keV)")
set_curve(["symbol.size",3])
set_curve(["symbol.color","red"])
set_curve(["err.color","red"])
limits(X_AXIS,0.3,12.5)
# limits(Y_AXIS,0.02,0.2)
log_scale()
set_xaxis(["minortick.count",4])
set_arbitrary_tick_positions([0.5,1.0,2.0,5.0,10.0])
limits(Y_AXIS,0.002,AUTO)
set_yaxis(["majortick.interval", 0.05,"minortick.count",4])
# ---> 4.3 Gráfico do blank-field
plot_bkg(overplot=True)
# log_scale()
# limits(X_AXIS,9.0,12.5)
# get_data_plot_prefs["linestyle"]=chips_dot
# get_data_plot_prefs["linestyle"]=chips_square
# print_window("spec_bkg.pdf", ["orientation", "landscape"])

# ---> 4.4 Salvando gráfico
print_window("spec_bkg.png",{"clobber":True})
