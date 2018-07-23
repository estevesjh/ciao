#!/bin/bash -f
### Dado um arquivo de eventos filtrado por expmap e lc_clean
### Sempre rode anteriormente o código centro.sh
### Ajusta um Brilho Superficial

evt=$1
r0=$2
rend=$3
quieto=$4

out="aneis.reg"
outb="aneis_bkg.reg"

rm bla.fits
dmcopy "${evt}[energy=${emin}":"${emax}]" bla.fits clobber=no

rm -f $out $outb

# # WCS coord. in degree
# ra=$(dmkeypar ${evt} RA_TARG echo+)
# dec=$(dmkeypar ${evt} DEC_TARG echo+)
#
# # Pix Scale in arcsec/pixel
# pset dmcoords ra=$ra
# pset dmcoords dec=$dec
# pixscale=$(dmcoords $evt asol=non option=cel x=$ra y=$dec verbose=1 | awk '/Sky pixel scale:/ {print $4}')
#
# # Center in physical coord.
# xcen=$(pget dmcoords x)
# ycen=$(pget dmcoords y)
# xfree=$(cat free.reg | awk -F'[(,]' '{print $2}')
# yfree=$(cat free.reg | awk -F'[(,]' '{print $3}')
# rfree=$(cat free.reg | awk -F'[(,)]' '{print $4}')
# echo "annulus($xfree,$yfree,0,$rfree)" > free.reg

#---------Definindo Anéis concentricos----------
ri=$(echo $r0 $pixscale | awk '{print $1 / $2}') # raio inicial em physical unit
rfim=$(echo $rend $pixscale | awk '{print $1 / $2}') # raio inicial em physical unit
ncir=$(echo $ri $rfim | awk '{print int( log(($2 / $1)-1) / log(1.05) )}') # Espessura do anel
ra=$ri


#--- Aneis
jj=1
while [ $jj -le $ncir ]; do
  rb=$(echo $ra $jj | awk '{print $1*(1.05)^(jj)}')
  echo "annulus($xcen,$ycen,$ra,$rb)" >> $out
  ra=$rb
  jj=$(($jj + 1))
done

# Anel do background
rbkg=$(echo $ri $rfim | awk '{print $2 + (0.2 * ($2 - $1))}')
echo "annulus($xcen,$ycen,$rfim,$rbkg)" > $outb
# espessura de 20 por centro do anel maior (rfinal - rinicial)

#---------Criando tabela, R,NET_COUNTS,NET_COUNTS_ERR-----------
punlearn dmextract
pset dmextract infile="$fimg[bin sky=@${out}]"
pset dmextract outfile=${obsid}_rprofile.fits
# pset dmextract bkg="$fimgbin sky=@${outb}]"
pset dmextract bkg="${blk}[bin sky=@${out}]"
pset dmextract exp = ${emap}
pset dmextract bkgexp = ${emap}
pset dmextract opt=generic
dmextract mode=h

punlearn dmtcalc
pset dmtcalc infile=${obsid}_rprofile.fits
pset dmtcalc outfile=${obsid}_rprofile_rmid.fits
pset dmtcalc expression="rmid=0.5*(R[0]+R[1])"
dmtcalc mode=h

punlearn specextract
pset specextract infile ="${evt}[sky=@aneis.reg]"
pset specextract outroot=fatia/anel
pset specextract bkgfile="${obsid}_blank.evt[sky=@aneis.reg]"
pset specextract grouptype="NUM_CTS"
pset specextract binspec=50
pset specextract bkgresp=no
specextract mode=h clobber+



# kT=7
# Z=0.00402
# norm=0.01
# cd fatia
# declare -a arf=(`ls -1 anel*.arf`)
# declare -a rmf=(`ls -1 anel*.rmf`)
# nbin=$(echo "${#arf[@]}")
# ii=0
# while [ $ii -le $(($nbin-1)) ]; do
#   modelflux arf="${arf[${ii}]}" rmf="${rmf[${ii}]}" model="xsphabs.abs1*xsapec.p1" paramvals="abs1.nh=0.07;p1.kT=${kT};p1.Abundanc=${Z};p1.norm=${norm}" emin=0.7 emax=2
#   echo $(pget modelflux rate pflux flux | tail -n 1) >> cnt_rate
#   ii=$(($ii+1))
# done



sherpa $CODE/beta1d.py

# #--- Calculando XXXX (Scaling factor of background)
# dmcopy "${evt}[energy=9500:12000]" high_energy_bg.fits
# pset dmextract infile="high_energy_bg.fits[bin sky=@$aper]"
# pset dmextract outfile=bg_counts.fits
# dmextract mode=h
#
# dmlist bg_counts.fits'[cols R, COUNTS]'
#
# exp="fluximage.expmap"
# in="fluximage.img"
# bg="fluximage.bgimg"
#
# get_sky_limits ${exp}
# dmf=`pget get_sky_limits dmfilter`
# dmcopy "${bg}[bin $dmf]" bkg.bgimg
#
# dmimgcalc ${in},"bkg.bgimg",${ep} none foo.img op="imgout=((img1-XXXX*img2)/img3)"
