#!/bin/bash -f
### Subtrai o background
### Usando um blankfield

obsid=$1
ps=$2
quieto=$3

evt=`ls acisf${obsid}_repro_evt*`
emin=500
emax=7000

#### Removing Flares
dmgti lc.fits gti.fits userlimit="rate<2"

dmextract "${evt}[energy=$emin:$emax][bin time=::200]" lc.fits op=ltc1
deflare "lc.fits[count_rate<2]" outfile=lc.gti method=sigma
# deflare flare.lc flare.gti clean plot+
dmcopy "${evt}[@flare.gti]" ${obsid}_gti_evt2.fits
