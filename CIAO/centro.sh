#!/bin/bash -f

## Dado um arquivo de eventos Chandra
## acha o centroid da fonte mais importante
## Pode funcionar se so' hoverem fontes pontuais e/ou
## subestrutura fraca

## Adaptado por Johnny 22/05/2018 de Gastao 16/04/2018

if [ "$#" != 5 ]; then
    echo
    echo "Uso: def_centro.sh  obsid  emin(eV)  emax(eV)  bin  quieto"
    echo "Lembrando, obsid deve ter 5 algarismos, ex: obsid 533, use 00533"
    echo "quieto = 0  => so' o resultado final"
    echo "quieto = 1  => tagarela"
fi

obsid=$1     ## nome do arquivo de eventos
raper=$2     # em Segundos de arco
quieto=$3  ## com ou sem output(verbose) intermediario

binimg=4  #  como a imagem e' binada : o resultado e' em funcao desta binagem
evt=`ls *_repro_evt*`

# evt=`ls acisf${obsid}_repro_evt*`
# rin=150   ## em arcsec --  raio do circulo inicial dentro de onde procuramos o centro
echo $raper
filtroEnergy="700:2000"
bla="evt_bin_${binimg}.fits"
toto="toto_img.fits"
totog=$(echo ${toto//.fits/_gau.fits})
centreg="centroid.reg"

dmcopy "$evt[energy=$filtroEnergy][bin sky=${binimg}]" $bla

# WCS coord. in degree
ra=$(dmkeypar ${evt} RA_TARG echo+)
dec=$(dmkeypar ${evt} DEC_TARG echo+)

# Pix Scale in arcsec/pixel
pset dmcoords ra=$ra
pset dmcoords dec=$dec
pixscale=$(dmcoords $evt asol=non option=cel x=$ra y=$dec verbose=1 | awk '/Sky pixel scale:/ {print $4}')


# Center in physical coord.
xcen=$(pget dmcoords x)
ycen=$(pget dmcoords y)

rinPHY=$(echo $raper $pixscale | awk '{print $1 / $2}')

echo "centro: "$xcen ", "$ycen ," R(physical) = " $rinPHY
#
ii=1
# - - - - - - - - - - -  INICIO do LOOP - - - - - - - - - -
while [ "$ii" -le 6 ]; do

if [ "$quieto" == 1 ]; then
 echo "centro: "$xcen ", "$ycen ," R(physical) = " $rinPHY
fi

regiao="circle($xcen,$ycen,$rinPHY)"
echo $regiao > ape.reg

# extrai a imagem
dmcopy "${bla}[sky=region(ape.reg)]" $toto clob+

# smooth a imagem com uma gaussiana (evita ruidos indesejaveis)
# fgauss $toto $totog 2
# dmimgadapt $toto out=$totog min=1 max=45 num=45 radscal=log fun=gaus counts=25 verb=3 clob+
aconvolve $toto $totog kernelspec='lib:gaus(2,2,1,3,3)' clobber=yes

## Acha o centroide --- OBS usa dmstat do CIAO/Chandra
punlearn dmstat
dmstat $totog centroid=yes > /dev/null
xcen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $1}')
ycen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $2}')

## refaz com o novo centroid, mas mesmo raio
regiao="circle($xcen,$ycen,$rinPHY)"
echo "centro: "$xcen ", "$ycen ," R(physical) = " $rinPHY
rm -f $toto $totog
dmcopy "$bla[sky=$regiao]" $toto

# smooth a imagem com uma gaussiana (evita ruidos indesejaveis)
aconvolve $toto $totog kernelspec='lib:gaus(2,2,1,3,3)' clobber=yes

## Acha o centroide --- OBS usa dmstat do CIAO/Chandra
punlearn dmstat
dmstat $totog centroid=yes > /dev/null
xcen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $1}')
ycen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $2}')

ii=$(($ii + 1))

## Encolhe o raio na quinta interação
if [ $ii == 3 ]; then
  rinPHY=$(echo $rinPHY | awk '{print $1 / 3.0}')
fi
4094.50
done ## while
# - - - - - - - - - - -  FIM do LOOP - - - - - - - - - -

punlearn dmcoords
pset dmcoords x=$xcen
pset dmcoords y=$ycen
dmcoords $evt asol=non option=sky x=$xcen y=$ycen celfmt=deg verbose=0
# Center in RA and DEC
ra=$(pget dmcoords ra)
dec=$(pget dmcoords dec)

echo
echo "X_ctrd_phy = "$xcen ", Y_ctrd_phy = "$ycen
echo
#
# ## cria um .reg ciao/physical
#
# rm -f $centreg
# rinPHY=$(echo $rinPHY | awk '{print $1 / 5.0}')
# echo "circle("$xcen","$ycen","$rinPHY")" > $centreg
#
# if [ $quieto ==  1 ]; then
#   echo "regiao ciao/physical : " $centreg
#   echo
# fi
# ASCDS_CONTRIB="/home/johnny/ciao/ciao-4.10/contrib/"
#
# # if [ $quieto ==  1 ]; then
# #    ds9 $evt -bin factor $binimg -scale log -regions -format ciao $centreg -smooth -cmap load $ASCDS_CONTRIB/data/purple4.lut &
# # fi
#
# rm -f $toto $totog $bla
# # http://cxc.harvard.edu/ciao/threads/auxlut/#ds9_loweng
# # xcen=$(cat cen.txt | awk -F"," '{print $1}')
# # ycen=$(cat cen.txt | awk -F"," '{print $2}')
