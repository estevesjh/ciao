#!/bin/bash -f
### Dado um obsid ecnontra as fontes pontuais ou extensas
### retorna a lista de fontes em ps.reg

obsid=$1
emin=$2
emax=$3
quieto=$2

evt=`ls *_repro_evt*`
scale="1 2"
out="ps.reg"

# Create counts image and exposure map
fluximage ${evt} ${obsid} bin=4 band=${emin}:${emax}:1.5 verbose=${quieto}

psimg="${obsid}_${emin}-${emax}_thresh.img"

# Create PSF map
mkpsfmap $psimg ${obsid}_${emin}-${emax}_thresh.psfmap energy=1.5 ecf=0.9 mode=h clob+

# Run wavdetect
punlearn wavdetect
pset wavdetect infile=${obsid}_${emin}-${emax}_thresh.img
# pset wavdetect psffile=${obsid}_${emin}-${emax}_thresh.psfmap
pset wavdetect expfile=${obsid}_${emin}-${emax}_thresh.expmap
pset wavdetect scales=${scale}
pset wavdetect outfile=${out}
pset wavdetect scell=${obsid}_${emin}-${emax}.cell
pset wavdetect imagefile=${obsid}_${emin}-${emax}.recon
pset wavdetect defnbkg=${obsid}_${emin}-${emax}.nbkg
pset wavdetect interdir=./ mode=h clob+
pset wavdetect sigthresh=1e-6

echo "---> rodando wavdetect!"
wavdetect

# Busca no CSC

# Por obsid
# obsid_search_csc ${obsid} out=${obsid}.tsv column=o.theta,o.cnts_aper_b,o.ks_prob_b,o.flux_significance_b verb=0

# Por posição
# search_csc pos="${ra},${dec}" radius=20 out=${obsid}.tsv column=o.theta,o.cnts_aper_b,o.ks_prob_b,o.flux_significance_b verb=0
#
# dmlist "${obsid}.tsv[opt kernel=text/tsv]" cols
# ds9 $fimg -catalog import tsv ${obsid}.tsv
# http://cxc.harvard.edu/ciao/threads/csccli/
