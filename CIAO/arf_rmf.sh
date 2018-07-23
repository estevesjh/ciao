# Criando arquivos ARF e RMF
# variavéis necessárias psevt, blk
quieto=$1

blk="${obsid}_blank.evt"
psevt="evt_gti_ps.fits"
# rinPHY=$(echo $rin $pixscale | awk '{print $1 / $2}')
# regiao="annulus($xcen,$ycen,$rinPHY,$rextPHY)"

#---- Creating an ARF and RMF files
if [ "$(ls spec)" = "" ]; then
  # mkdir spec
  #-----Reigão da Fonte Extensa-----
  punlearn specextract
  pset specextract infile="${psevt}[sky=region(source.reg)]"
  pset specextract outroot=spec/source
  pset specextract bkgfile="${blk}[sky=region(source.reg)]"
  pset specextract grouptype="NUM_CTS"
  pset specextract binspec=50
  pset specextract bkgresp=no
  specextract mode=h verbose=$quieto

  #-----Reigão do background-----
  pset specextract infile="${psevt}[sky=region(bkg.reg)]"
  pset specextract outroot=spec/bkg
  specextract mode=h

  dmhedit spec/bkg.pi key=BACKFILE value=source_bkg.pi
fi

dmstat "${obsid}_rprofile_rmid.fits[cols rmid][rmid<$rextPHY]" data verbose=0
ncir_s=$(pget dmstat out_good);ri=$(pget dmstat out_min)
#---------Definindo Anéis concentricos----------
if [ "$(ls fatia)" = "" ]; then
  # Numero de aneis
  ra=$ri
  jj=1
  while [ $jj -le $ncir_s ]; do
    rb=$(echo $ri $jj | awk '{print $1*(1.05)^($2)}')
    echo "annulus($xcen,$ycen,$ra,$rb)" >> fatia.reg
    ra=$rb
    jj=$(($jj + 1))
  done
  punlearn specextract
  pset specextract infile ="${psevt}[sky=@fatia.reg]"
  pset specextract outroot=fatia/anel
  pset specextract bkgfile="${blk}[sky=@fatia.reg]"
  pset specextract grouptype="NUM_CTS"
  pset specextract binspec=50
  pset specextract bkgresp=no
  specextract mode=h clobber+ verbose=$quieto
fi

echo $(ls -1 fatia/anel*.arf) > lista.arf
echo $(ls -1 fatia/anel*.rmf) > lista.rmf

# echo "0. Normalizado o background"
#
# bla="in_step.fits"
# blaa="bkg_step.fits"
#
# rm -f $bla $blaa
#
# dmcopy "${psevt}[bin sky=4][energy=9500:12000]" $bla
# dmcopy "${blk}[bin sky=4][energy=9500:12000]" $blaa
#
# punlearn dmextract
# pset dmextract op=generic
# dmextract "$bla[bin sky=region(source.reg)]" simple.fits
# dmextract "$blaa[bin sky=region(source.reg)]" simple_bkg.fits
#
# dmstat "simple.fits[col COUNT_RATE]"
# srate=$(pget dmstat out_min)
# dmstat "simple_bkg.fits[col COUNT_RATE]"
# bgrate=$(pget dmstat out_min)
#
# bkgnorm=$(echo $srate $bgrate | awk '{print $1 / $2}')
# rm -f $bla $blaa simple.fits simple_bkg.fits
#
# echo "Trocando o valor do bkgnorm"
# # in="1" out="$bkgnorm" perl -pi -e 's/bkgnorm,r,h,\Q$ENV{"in"}/bkgnorm,r,h,$ENV{"out"}/g' ~/ciao/ciao-4.10/param/dmextract.par
#
# echo "COUNTS=(COUNTS*${bkgnorm})" > calc.lis
# echo "COUNT_RATE=(COUNT_RATE*${bkgnorm})" >> calc.lis
# echo "O valor de BGscale é :" $bkgnorm
# echo "--------------------------------------------------------------------------"
#
# dmcopy "${psevt}[sky=region(source.reg)]" $bla
# dmcopy "${blk}[bin sky=4]" $blaa
#
# #echo "0. Normalizado o background"
# punlearn dmtcalc
# pset dmtcalc infile=bkg.pi
# pset dmtcalc outfile=bkg_bkg.pi
# pset dmtcalc expression=@calc.lis
# pset dmtcalc clob=yes
# dmtcalc mode=h

# Voltando o Parâmetro bkgnorm para Default
# in="$bkgnorm" out="1" perl -pi -e 's/bkgnorm,r,h,\Q$ENV{"in"}/bkgnorm,r,h,$ENV{"out"}/g' ~/ciao/ciao-4.10/param/dmextract.par


# if [ "$(ls fatia)" = "" ]; then
#   mdkir fatia
#   #-----Reigão da Fonte Extensa-----
#   punlearn specextract
#   pset specextract infile ="${psevt}[sky=@aneis.reg]"
#   pset specextract outroot=fatia/anel
#   pset specextract bkgfile="${obsid}_blank.evt[sky=@aneis.reg]"
#   pset specextract grouptype="NUM_CTS"
#   pset specextract binspec=50
#   pset specextract bkgresp=no
#   specextract mode=h
# fi

# blk: "${obsid}_blank.evt"
