# Essa função limpa flares
# rode primeiro pipeline.sh

obsid=$1
quieto=$2

#---- Limpando Flares
aux="bla.fits"
dmcopy "${evt}[energy=300:12000]" ${aux}

punlearn dmextract
dmextract "${aux}[bin time=::259.28]" lc.fits op=ltc1
deflare "lc.fits" outfile=lc.gti method=clean
dmcopy "${evt}[@lc.gti]" evt_gti.fits
# dmextract "bla_excl.fits[bin time=84348993.8047791272:84386219.8896973729:259.28]" lc.fits op=ltc1
# Definindo os bons intervalos de tempo
rm ${aux}
