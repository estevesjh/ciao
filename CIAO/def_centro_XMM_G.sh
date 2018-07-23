#!/bin/bash -f

## Dado um arquivo de eventos XMM (de preferencia limpo)
## acha o centroid da fonte mais importante
## Pode funcionar se so' hoverem fontes pontuais e/ou
## subestrutura fraca

## Gastao 16/04/2018

if [ "$#" != 5 ]; then
    echo
    echo "Uso: def_centro_XMM_G.sh  arquivo_eventos.fits  emin(eV)  emax(eV)  bin  quieto"
    echo
    echo "quieto = 0  => so' o resultado final"
    echo "quieto = 1  => tagarela"
fi

evt=$1     ## nome do arquivo de eventos
emin=$2    #  em eV
semax=$3    #  em eV
binimg=$4  #  como a imagem e' binada : o resultado e' em funcao desta binagem
quieto=$5  ## com ou sem output(verbose) intermediario

rin=10.0   ## em ARCMIN --  raio do circulo inicial dentro de onde procuramos o centro


xcen=$(fkeyprint $evt"[0]" REFXCRPX | grep WCS | awk '{print $2}')
ycen=$(fkeyprint $evt"[0]" REFYCRPX | grep WCS | awk '{print $2}')

pix=$(fkeyprint $evt"[0]" REFYCDLT | grep WCS |awk '{print $2}')
pix=$(echo $pix | awk '{print $1 * 3600.}')

rinPHY=$(echo $rin $pix | awk '{print $1 * 60. / $2}')

filtroEnergy="(PI in ("$emin":"$emax"))"
toto="toto_img.fits"
totog=$(echo $toto:r"_gau.fits")
centreg="centroid.reg"

ii=1
# - - - - - - - - - - -  INICIO do LOOP - - - - - - - - - -
while [ $ii -le 6 ]; do

if [ $quieto == 1 ]; then
 echo "centro: "$xcen ", "$ycen " R(physical) = "$rinPHY
fi

regiao="((X,Y) IN circle($xcen,$ycen,$rinPHY))"

rm -f $toto $totog

# extrai a imagem
evselect table=$evt':EVENTS' filtertype='expression' expression="$regiao && $filtroEnergy" imageset=$toto imagedatatype=Real32 xcolumn='X' ycolumn='Y' imagebinning='binSize' squarepixels=yes ximagebinsize=$binimg yimagebinsize=$binimg -V 0

# smooth a imagem com uma gaussiana (evita ruidos indesejaveis)

fgauss $toto $totog 2

## Acha o centroide --- OBS usa dmstat do CIAO/Chandra
punlearn dmstat
dmstat $totog centroid=yes > /dev/null
xcen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $1}')
ycen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $2}')

## refaz com o novo centroid, mas mesmo raio

regiao="((X,Y) IN circle($xcen,$ycen,$rinPHY))"

rm -f $toto $totog

# extrai a imagem
evselect table=$evt':EVENTS' filtertype='expression' expression="$regiao && $filtroEnergy" imageset=$toto imagedatatype=Real32 xcolumn='X' ycolumn='Y' imagebinning='binSize' squarepixels=yes ximagebinsize=$binimg yimagebinsize=$binimg -V 0

# smooth a imagem com uma gaussiana (evita ruidos indesejaveis)

fgauss $toto $totog 2

## Acha o centroide --- OBS usa dmstat do CIAO/Chandra
punlearn dmstat
dmstat $totog centroid=yes > /dev/null
xcen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $1}')
ycen=$(pget dmstat out_cntrd_phys | sed 's/,/ /g'|awk '{print $2}')

## Encolhe o raio
rinPHY=$(echo $rinPHY | awk '{print $1 / 1.75}')

ii=$(($ii + 1))

done ## while
# - - - - - - - - - - -  FIM do LOOP - - - - - - - - - -


echo
echo "X_ctrd_phy = "$xcen ", Y_ctrd_phy = "$ycen
echo

## cria um .reg ciao/physical

rm -f $centreg

echo "circle("$xcen","$ycen","$rinPHY")" > $centreg

if [ $quieto ==  1 ]; then
  echo "regiao ciao/physical : " $centreg
  echo
fi

if [ $quieto ==  1 ]; then
   ds9 $evt -bin factor $binimg -scale sqrt -regions -format ciao $centreg &
fi

rm -f $toto $totog
