import numpy as np
from sherpa_contrib.all import *
from sherpa.astro.ui import *

load_data(1,'SB_flux.fits', 3, ["RMID","NET_RATE","ERR_RATE"])

pars = ["rc","rs","alpha","beta","epsilon","gamma","n0"]
load_user_model(Eprojected,"mybeta")
par0 = [80,400,0.5,1.0,1.0,3.0,0.0210105]
frzpar=5*[False]+[True,False]

add_user_pars("mybeta", pars, par0, parfrozen=frzpar)
set_model("mybeta")

mybeta.rc.min = 0
mybeta.rc.max = 1e6
mybeta.rs.min = 0
mybeta.rs.max = 1e6
mybeta.alpha.min = 1e-5
mybeta.alpha.max = 1e2
mybeta.beta.min = 0
mybeta.beta.max = 1e2
mybeta.epsilon.min = 0
mybeta.epsilon.max = (5-1e-3)
mybeta.gamma.min = 1e-5
mybeta.n0.min = 0

show_model()
fit()
fitr = get_fit_results()
plot_fit_delchi()
