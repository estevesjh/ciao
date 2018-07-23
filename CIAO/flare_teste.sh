# #### Subtraindo o bkg
# pset blanksky evtfile="${evt}[@flare.gti]"
# pset blanksky outfile=${obsid}_blank.evt
# pset blanksky tmpdir=./
# blanksky mode=h
#
# pset blanksky_image bkgfile=${obsid}_blank.evt
# pset blanksky_image outroot=${obsid}_blank
# pset blanksky_image imgfile=${obsid}.${iVEC}.thresh.img
# pset blanksky_image tmpdir=./
# blanksky_image mode=h clob+
#
# ## Creating an ARF and RMF files
# punlearn specextract
# mdkir spec
# pset specextract infile="${evt}[sky=region(simple.reg)]"
# pset specextract outroot=spec/simple
# pset specextract bkgfile="${obsid}_blank.evt[sky=region(simple.reg)]"
# pset specextract bkgresp="no"
#
# specextract mode=h
#
# # #### ARF and MRF files
# #
# # punlearn specextract
# # pset specextract infile="${evt}.fits[sky=region(simple.reg)]"
# # pset specextract outroot=simple
# # pset specextract bkgfile="${obsid}.fits[sky=region(ds9_bkg.reg)]"
# #
# # specextract mode=h
#
# ### Fit a Radial Profile
#
# dmcopy "${evt}[energy=500:7000]" ${obsid}.fits
# # Make the annuli regions using the ds9
# ds9 ${obsid}.fits &
# # Removing the point sources
# dmcopy "${evt}[exclude sky=region(${obsid}_broad.reg)]" ${obsid}_excl_evt2.fits
#
# # Making the brightness profile
# punlearn dmextract
# pset dmextract infile="${obsid}_excl_evt2.fits[bin sky=@annuli.reg]"
# pset dmextract outfile=${obsid}_rprofile.fits
# pset dmextract bkg="${obsid}_excl_evt2.fits[bin sky=@annuli_bkg.reg]"
# pset dmextract opt=generic
# dmextract
#
# # Binning the data in r_mean
# punlearn dmtcalc
# pset dmtcalc infile=1838_rprofile.fits
# pset dmtcalc outfile=1838_rprofile_rmid.fits
# pset dmtcalc expression="rmid=0.5*(R[0]+R[1])"
# dmtcalc
#
# ## Fiting a beta 1D model
# sherpa
# load_data(1,"12247_rprofile_rmid.fits",3,["RMID","SUR_BRI","SUR_BRI_ERR"])
#
# set_source("beta1d.src")
# src.r0 = 100
# src.beta = 1
# src.ampl = 1
# freeze(src.xpos)
#
# fit()
# plot_fit()
# log_scale()
# save_all(outfile="results.txt", clobber=False)
# exit


## Complicate Way (Input: sources regions and chip number)
# dmcopy "${evt}[energy=500:7000, ccd_id=3, bin sky=8]" ${obsid}.fits
# dmcopy "$evt[exclude sky=region(sources.reg)]" ${obsid}_bg.fits
# #
# dmlist ${obsid}_bg.fits"[GTI3]" data > gti.txt
# tmin=`sed -n '8{p;q}' gti.txt | awk '{print $2 FS $8}'`
# tmax=`sed -n '8{p;q}' gti.txt | awk '{print $3 FS $8}'`
# #
# punlearn dmextract
# pset dmextract infile="${obsid}_bg.fits[bin time=${tmin//[[:blank:]]/}:${tmax//[[:blank:]]/}]"
# pset dmextract outfile=${obsid}_bg.lc
# pset dmextract opt=ltc1
# dmextract
#
# deflare ${obsid}_bg.lc ${obsid}_bg_deflare.gti method=clean
## dmcopy "${obsid}.fits[@${obsid}_bg_deflare.gti]" ${obsid}_clean.fits Tem algum bug
