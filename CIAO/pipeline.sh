#!/bin/bash -f
# pip.main(['install','sympy','--user'])
### Dado um arquivo de eventos Chandra
### encontra as fontes pontuais
### acha o centroid da fonte mais importante
### filtra light flares (lc_clean)
### subtrai o background
### Corrige por mapa de exposição

CODE="/home/johnny/Documents/Master/CIAO"
obsid=$1     ## nome do arquivo de eventos
quieto=$2  ## com ou sem output(verbose) intermediario
echo "---------------------------------------------------------------------"
echo "------------------------ Johnny Pipeline I --------------------------"
echo "---------------------------------------------------------------------"
ciao
echo "---------------------------------------------------------------------"
if [ "$#" != 5 ]; then
    echo
    echo "Uso: pipeline.sh  obsid quieto"
    echo "quieto = 0  => so' o resultado final"
    echo "quieto = 1  => tagarela"
    echo "---------------------------------------------------------------------"
fi
pwd
z=0.722 # Redshift do aglomerado
binimg=4  #  como a imagem e' binada : o resultado e' em funcao desta binagem

echo "---------------------------------------------------------------------"
echo "------------------ Primeira PARTE: Preparção ------------------------"
echo "---------------------------------------------------------------------"

dow=`ls *$obsid*`
python="cluster.txt"

# echo "--------------------- Baixando os dados -----------------------------"
# if [ "$dow" = "" ]; then
#   download_chandra_obsid $obsid
#   cd $obsid
#   pwd
# fi
# echo "-----------------Reprocessando os dados lvl. 2-----------------------"
# pset chandra_repro check_vf_pha=yes
# punlearn chandra_repro
# chandra_repro mode=h verbose=$quieto
# cd repro
# pwd

# evt=`ls *_repro_evt*`
#
# echo "---------------------------------------------------------------------"
# echo "------------------Encontrando fontes pontuais------------------------"
# psemink=0.3  # em keV
# psemaxk=7    # em keV
# source $CODE/wavelet.sh ${obsid} $psemink $psemaxk ${quieto}
# # output is ps.reg
# # band=emin:emax:expmap_energy
# echo "---------------------------------------------------------------------"
# echo "----------------------Limpando Flares--------------------------------"
# source $CODE/flare.sh ${obsid} ${quieto}
# evtgti="evt_gti.fits"
# # dmcopy "$evtgti[bin sky=$binimg]" "evt2_gti.fits"
# evt2=`ls evt_gti.fits`
# #-- Redefine o arquivo de eventos
#
# echo "---------------------------------------------------------------------"
# echo "--------------------Encontrando o centro-----------------------------"
# raper=150
# source $CODE/centro.sh $obsid $raper $quieto
# # output é centroid.reg
#
# echo "obsid, xcen, ycen, z, pixscale" > $python
# echo "${obsid}, ${xcen}, ${ycen}, ${z}, ${pixscale}" >> $python
# Guardando dados básicos do aglomerado para ser importado no python
# #
# echo "---------------------------------------------------------------------"
# echo "--------------------Criando blank-field------------------------------"
# source $CODE/blank_sky.sh $obsid $quieto
# bg="blank.bgimg"
# blk="${obsid}_blank.evt"
#
# echo "---------------------------------------------------------------------"
# echo "--------------------Conferindo os dados------------------------------"
# echo "---------------------------------------------------------------------"
# echo "-------> Cheque as fonts pontuais -----------------------------------"
# ds9 $psimg -scale log -regions -format ciao ps.reg -smooth -zoom to fit -saveimage ps.png -cmap load $ASCDS_CONTRIB/data/purple4.lut &
# return
# echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
echo "------------------ Segunda PARTE: Análise ---------------------------"
echo "---------------------------------------------------------------------"

# echo "---------------------------------------------------------------------"
# echo "-------------------Mascarando as fontes pontuais---------------------"
# psevt=$(echo ${evt2//.fits/_ps.fits})
# dmcopy "${evtgti}[exclude sky=region(ps.reg)]" $psevt clob+
#
# echo "---------------------------------------------------------------------"
# echo "---------------------Criando mapa de exposição-----------------------"
# emink=0.7    # em keV
# emaxk=2      # em keV
# # Create counts image and exposure map
# fluximage $psevt $obsid bin=4 band=${emink}:${emaxk}:1.5 clobber=yes verbose=${quieto}
# emap="${obsid}_${emink}-${emaxk}_thresh.expmap"
# fimg="${obsid}_${emink}-${emaxk}_thresh.img"

# echo "---------------------------------------------------------------------"
# echo "--------------------Extraindo Perfil Radial--------------------------"
# Perfil radial sem fontes pontuais
# r0=30; rend=300
# source $CODE/rprofile.sh $r0 $rend $quieto

# echo "---------------------------------------------------------------------"
# echo "----------------------Arquivos ARF e RMF-----------------------------"
# source $CODE/arf_rmf.sh $quieto

# echo "---------------------------------------------------------------------"
# echo "----------------------Ajuste Espectral: Background-------------------"
# sherpa $CODE/spec_bkg.py

# echo "---------------------------------------------------------------------"
# echo "--------------Ajuste Espectral: Temperatura e Metalicidade-----------"
# python $CODE/spec.py
#
# echo "---------------------------------------------------------------------"
# echo "-------------------Conversão de Contagens Fluxo----------------------"
# python $CODE/flux_conv.py
#
# Obs.: Assumimos um r500 pela relação M-T Vikhlinin et al. 2006, a fim de calcular o perfil de Temperatura. E por fim, estimar a conversão em fluxo.

# echo "---------------------------------------------------------------------"
# echo "--------------------Perfil de Densidade do Gás-----------------------"
# python $CODE/density.py

## output is spec.txt (kT, Abundance, Norm, Flux)
#---- Convertendo Contagens para fluxo
#
#
# #---- Ajustando o Brilho Superficial
# ##--- Beta 1D
# # emin=700    #  em eV
# # emax=2000   #  em eV
# source $CODE/radial_profile.sh ${evtc} 30 300 ${quieto}
# # output is bet1d_results.txt
#
# ##--- Beta 2D (Image)
# aper=300 # segundos de arco
# aper_phy=$(echo $aper $pixscale | awk '{print $1 / $2}')
# echo "circle($xcen,$ycen,$aper_phy)" > ape.reg
# dmcopy "evt2.fits[bin sky=region(ape.reg)]" image.fits
#
# sherpa $code/beta2d.py
#
# kT=$(awk '{print $1}' spec.txt | tail -n 1)
# Z=$(awk '{print $2}' spec.txt | tail -n 1)
# norm=$(awk '{print $3}' spec.txt | tail -n 1)
#
# modelflux arf="spec/simple.arf" rmf="spec/simple.rmf" model="xsphabs.abs1*xsapec.p1" paramvals="abs1.nh=0.07;p1.kT=${kT};p1.Abundanc=${Z};p1.norm=${norm}" emin=0.7 emax=2
# cnt_erg=$(pget modelflux rate pflux flux | tail -n 1)
#
#
# #---- Encontrando Massa do Halo
# rc=$(awk '{print $2}' beta2d.txt | tail -n 1)
# alpha=$(awk '{print $4}' beta2d.txt | tail -n 1)
# ampl=$(awk '{print $3}' beta2d.txt | tail -n 1)
#
# r500
# #---- Encontrando Massa do Gás
# sherpa $CODE/m_gas.py
# S0=$(echo $ampl $cnt_erg | awk '{print $1 * $2}') # Brilho Superficial 0
