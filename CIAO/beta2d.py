from sherpa_contrib.all import *
from sherpa_contrib.profiles import *
import astropy.io.ascii as at

a=at.read("cluster.txt")
obsid=str(a["obsid"][0])
xcen=a["xra"][0]
ycen=a["xdec"][0]

load_image("image.fits")
# load_table_model("emap", "expmap.fits")
# print(emap)

set_coord("physical")
set_full_model(const2d.bgnd + beta2d.ext)
# set_full_model(emap*(const2d.bgnd + beta2d.ext))

ext.xpos = xcen
ext.ypos = ycen
ext.alpha = 0.8
bgnd.c0 = 0.04
freeze(ext.ellip, ext.theta, ext.xpos, ext.ypos)
# freeze(ext.xpos,ext.ypos)

show_model()
set_stat("cstat") #CStat - A maximum likelihood function (XSPEC implementation of Cash); the background must be fitted
set_method("neldermead")
fit()
covariance()

image_data()
image_resid(tile=True, newframe=True)
image_source_component(ext, tile=True, newframe=True)

save_model("model.fits")
save_resid("resid.fits")

c = get_covariance_results()
# out = numpy.array([c.parvals,c.parmins, c.parmaxes])
# out[:,1] = out[:,1]*pixscale

at.write(numpy.array([c.parvals, c.parmins, c.parmaxes]), "beta2d.txt", names=c.parnames)

exit
