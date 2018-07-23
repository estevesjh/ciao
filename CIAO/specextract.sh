# http://cxc.harvard.edu/ciao/threads/extended/
# Esse código cria arquivos ARF e RMF com o background normalizado
# Entrada: evt.fits blank-file.fits outfile
# Criado em 21 de Junho de 2018 por Johnny H. Esteves

in=$1
bkgfile=$2
out=$3

evt=$(ls acisf*_repro_evt*)
echo "--------------------------------------------------------------------------"
echo "----------------------0. Normalizado o background-------------------------"

bla="in_step.fits"
blaa="bkg_step.fits"

dmcopy "${in}[bin sky=4][energy=9500:12000]" $bla
dmcopy "${bkgfile}[bin sky=4][energy=9500:12000]" $blaa

punlearn dmextract
pset dmextract op=generic
dmextract "$bla[bin sky=region(source.reg)]" simple.fits
dmextract "$blaa[bin sky=region(source.reg)]" simple_bkg.fits

dmstat "simple.fits[col COUNT_RATE]"
srate=$(pget dmstat out_min)
dmstat "simple_bkg.fits[col COUNT_RATE]"
bgrate=$(pget dmstat out_min)

bkgnorm=$(echo $srate $bgrate | awk '{print $1 / $2}')
rm -f $bla $blaa simple.fits simple_bkg.fits

echo "COUNTS=(COUNTS*${bkgnorm})" > calc.lis
echo "COUNT_RATE=(COUNT_RATE*${bkgnorm})" >> calc.lis

echo "O valor de BGscale é :" $bkgnorm
echo "--------------------------------------------------------------------------"

echo "--------------------------------------------------------------------------"
echo "----------------------1. Extract spectra ---------------------------------"

# echo "1. Extract Source spectra"

punlearn dmextract
pset dmextract infile="${in}[sky=region(source.reg)][bin pi]"
pset dmextract outfile=${out}.pi
pset dmextract wmap="[energy=300:2000][bin tdet=8]"
pset dmextract op=pha1
dmextract mode=h
# echo "1.2 Extract Blank-file background spectrum"
punlearn dmextract
pset dmextract infile="${blk}[sky=region(source.reg)][bin pi]"
pset dmextract outfile=${out}_bkg.pi
pset dmextract wmap="[energy=300:2000][bin tdet=8]"
dmextract mode=h clob+

punlearn dmtcalc
pset dmtcalc infile=${out}_bkg.pi
pset dmtcalc outfile=${out}_bkg.pi
pset dmtcalc expression=@calc.lis
pset dmtcalc clob=yes
dmtcalc mode=h


echo "--------------------------------------------------------------------------"

# Cat aspect solution file
asp=$(ls *asol*.lis)
msk=$(ls *msk*.fits)

#Identifiy the ACIS CCD
chip=$(dmkeypar $in detnam echo+ | awk -F 'ACIS-' '{print $2}')
nchip=${#chip}; rm ccd.txt
ii=0
while [[ "$ii" -le $(($nchip-1)) ]]; do
  echo $ii
  teste=$(dmlist "${in}[sky=region(source.reg)][cols ccd_id]" data | awk '{print $2}'| grep ${chip:$ii:1} | head -n 1)
  if [ "$teste" = "" ]; then
    echo "ok"
  else
    ccd=${chip:$ii:1}
    punlearn asphist
    pset asphist infile=@${asp}
    pset asphist outfile=${out}_c${ii}.asphist
    pset asphist evtfile="${in}[ccd_id=$ccd]"
    asphist mode=h clob+
    echo $ccd >> ccd.txt
    echo "${out}_c${ii}.asphist" >> asp.lis
  fi
  ii=$(($ii + 1))
done

# echo "7) Unindo as imagens de cada chip"
punlearn dmappend
dmmerge @asp.lis $out.asphist
rm ${out}_c* asp.lis
echo "--------------------------------------------------------------------------"
echo "----------------------2. Criando ARF -------------------------------------"

# echo "2.1 Create source ARF"

# Create weight map for ARF
punlearn sky2tdet
pset sky2tdet infile="${in}[sky=region(source.reg)][energy=300:2000][bin sky=4]"
pset sky2tdet outfile="${out}_tdet.wmap[wmap]"
pset sky2tdet asphistfile="${out}.asphist"
sky2tdet mode=h

punlearn mkwarf
pset mkwarf infile="${out}_tdet.wmap[wmap]"
pset mkwarf outfile=${out}.arf
pset mkwarf egridspec=0.3:11.0:0.01
pset mkwarf mskfile=${msk}
pset mkwarf weightfile=${out}.wfef
mkwarf mode=h

echo "--------------------------------------------------------------------------"
echo "----------------------3. Calculate the source RMFs------------------------"

# echo "3.1 Calculate the source RMFs"
punlearn mkacisrmf
pset mkacisrmf infile=CALDB
pset mkacisrmf outfile=${out}.rmf
pset mkacisrmf energy=0.3:11.0:0.01
pset mkacisrmf channel=1:1024:1
pset mkacisrmf wmap="$out.pi[WMAP]"
mkacisrmf mode=h

# punlearn mkrmf
# pset mkrmf infile=CALDB
# pset mkacisrmf outfile="${out}_mkrmf.rmf"
# pset mkrmf axis1="energy=0:1"
# pset mkrmf axis2="pi=1:1024:1"
# pset mkrmf weights=${out}.wfef
# mkrmf mode=h

# echo "4. Update the Spectrum Files"

#Group the Source Spectrum (dmgroup)
punlearn dmgroup
pset dmgroup infile=${out}.pi
pset dmgroup outfile=${out}_grp.pi
pset dmgroup grouptype=NUM_CTS
pset dmgroup grouptypeval=50
pset dmgroup xcolumn=channel
pset dmgroup ycolumn=counts
dmgroup mode=h

# Retirando o spec/ e deixando apenas o nome do arquivo
outb=$(echo $out | awk -F'/' '{print $2}')

#Update File Headers (dmhedit)
punlearn dmhedit
pset dmhedit operation=add filelist="" mode=h
dmhedit ${out}.pi key=BACKFILE value=${outb}_bkg.pi
dmhedit ${out}.pi key=RESPFILE value=${outb}.rmf
dmhedit ${out}.pi key=ANCRFILE value=${outb}.arf
dmhedit ${out}_grp.pi key=BACKFILE value=${outb}_bkg.pi
dmhedit ${out}_grp.pi key=RESPFILE value=${outb}.rmf
dmhedit ${out}_grp.pi key=ANCRFILE value=${outb}.arf

echo "--------------------------------------------------------------------------"
echo "----------------------4. Verificando Norm. Bkg ---------------------------"

dmstat "${out}.pi[col COUNT_RATE]"
srate=$(pget dmstat out_sum)
dmstat "${out}_bkg.pi[col COUNT_RATE]"
bgrate=$(pget dmstat out_sum)

bkgnormv=$(echo $srate $bgrate | awk '{print $1 / $2}')

echo "Verificando o BGscale :" $bkgnormv
echo "--------------------------------------------------------------------------"
# dmhedit ${out}_bkg.pi operation=add key=RESPFILE value=${out}_bkg_mkacisrmf.rmf
# dmhedit ${out}_bkg.pi operation=add key=ANCRFILE value=${out}_bkg.arf
