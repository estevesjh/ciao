obsid=00533
Xcen=`awk -F'[(,]' '{print $2}' simple.reg`
Ycen=`awk -F'[(,]' '{print $3}' simple.reg`

# Create counts image and exposure map
fluximage acisf${obsid}_repro_evt2.fits ${obsid} bin=4 band=broad

# Create PSF map
mkpsfmap ${obsid}_broad_thresh.img ${obsid}_broad_thresh.psfmap energy=2.3 ecf=0.9 mode=h clob+

# Run wavdetect
punlearn wavdetect
wavdetect \
  infile=${obsid}_broad_thresh.img \
  psffile=${obsid}_broad_thresh.psfmap \
  expfile=${obsid}_broad_thresh.expmap \
  scales="1 2 4 8" \
  outfile=${obsid}_broad.reg \
  scell=${obsid}_broad.cell \
  imagefile=${obsid}_broad.recon \
  defnbkg=${obsid}_broad.nbkg \
  interdir=./ mode=h clob+

dmcopy "acisf${obsid}_repro_evt2.fits[sky=region(simple.reg)][bin sky=4][energy=500:7000]" bla.fits
dmcopy "bla.fits[exclude sky=region(${obsid}_broad.reg)]" image.fits
dmcopy "${obsid}_broad_thresh.expmap[sky=region(simple.reg)]" expmap.fits

sherpa
load_image("image.fits")
# load_table_model("emap", "expmap.fits")
# print(emap)

set_coord("physical")
# set_full_model(const2d.bgnd + beta2d.ext)
set_full_model(emap*(const2d.bgnd + beta2d.ext))

show_model()
ext.xpos = Xcen
ext.ypos = Ycen
ext.alpha = 0.8
bgnd.c0 = 0.04
# ext.ampl = 0.4
# ext.r0 = 7.5
# ext.ellip=0.3
# ext.theta=2.4

freeze(ext.ellip, ext.theta)
# freeze(emap)
# freeze(ext.xpos,ext.ypos)
# freeze(emap.ampl,bgnd,ext.theta,ext.ellip,ext.alpha)

show_model()
set_stat("cstat") #CStat - A maximum likelihood function (XSPEC implementation of Cash); the background must be fitted
set_method("neldermead")
fit()

# notice2d("box(4072.5,3943.5,85,85)")
# show_stat()
image_data()
image_resid(tile=True, newframe=True)
image_source_component(ext, tile=True, newframe=True)
save_all(outfile="results.txt", clobber=False)

# save("manual_fit.save")
# save_all("manual_fit.ascii")
# #restore("manual_fit.save")
# #execfile("manual_fit.ascii")
# script(filename="sherpa.log", clobber=False)
