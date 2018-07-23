# Criando Blank sky arquivos e imagens

obsid=$1
quieto=$2

punlearn blanksky_image
pset blanksky evtfile=${evt}
pset blanksky outfile=${obsid}_blank.evt
pset blanksky tmpdir=./
blanksky mode=h verbose=$quieto

# aspblk=$(blanksky mode=h verbose=1 | awk '/Aspect solution file/ {print $4}')

punlearn blanksky_image
pset blanksky_image bkgfile=${obsid}_blank.evt
pset blanksky_image outroot=${obsid}_blank
pset blanksky_image imgfile=$fimg
pset blanksky_image tmpdir=./
blanksky_image mode=h clob+

# bg="${obsid}_blank_particle_bgnd.img"
# get_sky_limits ${exp}
# dmf=`pget get_sky_limits dmfilter`
# dmcopy "${bg}[bin $binimg]" blank.bgimg

# dmimgcalc ${in},"bkg.img",${ep} none bg_thresh.img op="imgout=((img1-XXXX*img2)/img3)"

# Blank sky scale
# dmlist "00524_blank.evt" header |grep BKGSCAL | awk '{print $3}'
