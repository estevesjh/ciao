from sherpa_contrib.all import *
from sherpa_contrib.profiles import *
import astropy.io.ascii as at
from beta1d_mod import*
a=at.read("cluster.txt")
obsid=str(a["obsid"][0])
pixscale=float(a["pixscale"])
CODE="/home/johnny/Documents/Master/CIAO/"

if len(obsid)<5:
    obsid=(5-len(obsid))*"0"+obsid

load_data(1,obsid+"_rprofile_rmid.fits", 3, ["RMID","SUR_BRI","SUR_BRI_ERR"])

load_user_model(Eprojected,"mybeta")
par0 = [80,400,0.5,1.0,1.0,3.0,0.0210105]
frzpar=5*[False]+[True,False]

add_user_pars("mybeta", ["rc","rs","alpha","beta","epsilon","gamma","n0"], par0, parfrozen=frzpar)
set_model("mybeta")

fit()
fit = get_fit_results()
out = numpy.array(fit.parvals)
out[0] = out[0]*pixscale

at.write(out, "beta1d.txt", names=fit.parnames)

exit()
exit
exit
# ou também
# c = get_conf_results()
# at.write(numpy.array([c.parvals, c.parmins, c.parmaxes]), "beta2d.txt", names=c.parnames)
#

# save_all(outfile="beta1d_fit.txt", clobber=True)
