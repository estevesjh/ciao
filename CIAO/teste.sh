# Wavdetect

# Create counts image and exposure map
fluximage acisf${obsid}_repro_evt2.fits cdfs${obsid} bin=4 band=broad

# Create PSF map
mkpsfmap cdfs${obsid}_broad_thresh.img cdfs${obsid}_broad_thresh.psfmap energy=2.3 ecf=0.9 mode=h clob+

# Run wavdetect
punlearn wavdetect
wavdetect \
  infile=cdfs${obsid}_broad_thresh.img \
  psffile=cdfs${obsid}_broad_thresh.psfmap \
  expfile=cdfs${obsid}_broad_thresh.expmap \
  scales="1 2 4 6 8 12 16 24 32" \
  outfile=cdfs${obsid}_broad.src \
  scell=cdfs${obsid}_broad.cell \
  imagefile=cdfs${obsid}_broad.recon \
  defnbkg=cdfs${obsid}_broad.nbkg \
  interdir=./ mode=h clob+

ds9 cdfs${obsid}_broad_thresh.img

aper="aper.reg"
echo "circle($xcen,$ycen,$rbkg)" > $aper

#--- Calculando XXXX (Scaling factor of background)
dmcopy "${evt}[energy=9500:12000]" high_energy_bg.fits
pset dmextract infile="high_energy_bg.fits[bin sky=@$aper]"
pset dmextract outfile=bg_counts.fits
dmextract mode=h

dmlist bg_counts.fits'[cols R, COUNTS]'

exp="fluximage.expmap"
in="fluximage.img"
bg="fluximage.bgimg"

get_sky_limits ${exp}
dmf=`pget get_sky_limits dmfilter`
dmcopy "${bg}[bin $dmf]" bkg.bgimg

dmimgcalc ${in},"bkg.bgimg",${ep} none foo.img op="imgout=((img1-XXXX*img2)/img3)"
