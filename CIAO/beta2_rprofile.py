from sherpa_contrib.all import *
from sherpa_contrib.profiles import *

a=!cat cen.txt
xcen = float(a[0][0:7])
ycen = float(a[0][10:17])


load_image("image.fits")

set_coord("physical")
set_stat("cash")
set_method("simplex")


set_source(beta2d.ext)
set_source(ext + const2d.bgnd)

print(ext)

ext.r0 = 50
ext.xpos = xcen
ext.ypos = ycen

ext.alpha = 0.8
bgnd.c0 = 0.04
freeze(ext.ellip, ext.theta)
# freeze(ext.xpos,ext.ypos)
# freeze(ext.alpha)
fit()
covariance()

# get_data_prof_prefs()["xlog"] = True
# get_data_prof_prefs()["ylog"] = True
# get_resid_prof_prefs()["xlog"] = True
# prof_fit(label=False, group_counts=50)
# prof_fit_resid(label=False, group_counts=50)
# limits(X_AXIS, 2, 600)
# show_model()

save_all(outfile="b2d_rprofile.txt", clobber=False)
