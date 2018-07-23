### Esse código subtraio o brilho Superficial em aneis concentricos
### Define um raio exterior, (outer radius)
### esse raio separa entra a região de emissão e o background
### Entrada r0, rend; váriaveis necessárias obsid, xcen, ycen, pixscale, fimg, emap,blk
### Testo duas definições, a A) Maughan 2008 e B) johnny
### Ultima alteração 19/06/2018

r0=$1
rend=$2
quieto=$3

out="aneis.reg"
rm -f $out

# xcen=$(cat cen.txt | awk -F  ',' '{print $1}')
# ycen=$(at cen.txt | awk -F  ',' '{print $2}')
# pixscale=0.492
ri=$(echo $r0 $pixscale | awk '{print $1 / $2}') # raio inicial em physical unit
rfim=$(echo $rend $pixscale | awk '{print $1 / $2}') # raio inicial em physical unit

#---------Definindo Anéis concentricos----------
ncir=$(echo $ri $rfim | awk '{print int( log(($2 / $1)-1) / log(1.05) )}') # Numero de aneis
#--- Aneis
# Obs.: A espessura dos anéis foram definidas em prog. geometrica.
ra=$ri
jj=1
while [ $jj -le $ncir ]; do
  rb=$(echo $ri $jj | awk '{print $1*(1.05)^($2)}')
  echo "annulus($xcen,$ycen,$ra,$rb)" >> $out
  ra=$rb
  jj=$(($jj + 1))
done

# Extração do perfil radial
#---------Criando tabela, R,NET_COUNTS,NET_COUNTS_ERR-----------

punlearn dmextract
pset dmextract infile="$fimg[bin sky=@${out}]"
pset dmextract outfile=${obsid}_rprofile.fits
# pset dmextract bkg="$fimg[bin sky=@${outb}]"
pset dmextract bkg="${blk}[bin sky=@${out}]"
pset dmextract exp=${emap}
pset dmextract bkgexp=${emap}
pset dmextract opt=generic
dmextract mode=h clob+

punlearn dmtcalc
pset dmtcalc infile=${obsid}_rprofile.fits
pset dmtcalc outfile=${obsid}_rprofile_rmid.fits
pset dmtcalc expression="rmid=0.5*(R[0]+R[1])"
dmtcalc mode=h clob+

# A) Critério de Maughan
# Não está certo, pq não tratei o background apropriadamente
echo "--->Calculando o Raio Externo"
blabla="source.fits"
bgscale=1; jj=0; thresh=3
#------------------ INICIO DO LOP ------------------
while [ $jj -le 5 ]; do

punlearn dmtcalc
pset dmtcalc infile=${obsid}_rprofile_rmid.fits
pset dmtcalc outfile=$blabla
pset dmtcalc expression="NBG=(COUNT_RATE*BG_AREA/(${bgscale}*BG_RATE*AREA))"
pset dmtcalc clob=yes
dmtcalc mode=h

dmstat "$blabla[col RMID][NBG=$thresh:1000]" verbose=0
rextPHY=$(pget dmstat out_max); nr=$(pget dmstat out_good)

nmin=6; nmax=$nr;
kk=0; done=0
while [ $nmin -gt 1 ]; do
  rm -f teste.fits
  dmcopy "$blabla[#row=$(($nmax-$nmin)):$nmax]" teste.fits
  dmstat "teste.fits[col RMID][NBG>$thresh]" verbose=0
  rextPHY=$(pget dmstat out_max);nteste=$(pget dmstat out_good)
  ruim=$(($nmin-$nteste+1))
  if [ "$nteste" == "$(($nmin+1))" ]; then
    nmin=0
  fi
  nmax=$(($nmax-$ruim))
  nmin=$(($nmin-1))
done

rext=$(echo $rextPHY $pixscale | awk '{print ($1 * $2)}')

echo "O raio externo dentro de meio sigma de emissão é:" $rext " segundos de arco"
echo

#-----Definindo a escala do background-----
dmstat "$blabla[RMID=$rextPHY:$rfim][col COUNT_RATE]" verbose=0
cnt_source=$(pget dmstat out_sum)
dmstat "$blabla[RMID=$rextPHY:$rfim][col AREA]" verbose=0
area=$(pget dmstat out_max)
dmstat "$blabla[RMID=$rextPHY:$rfim][col BG_RATE]" verbose=0
cnt_bg=$(pget dmstat out_sum)
dmstat "$blabla[RMID=$rextPHY:$rfim][col BG_AREA]" verbose=0
bg_area=$(pget dmstat out_max)

bgscale=$(echo $cnt_source $cnt_bg $area $bg_area | awk '{print ($1 / $2) * ($4 / $3)}')

echo "BG scaling :"$bgscale
echo

jj=$(($jj+1))
if [ $jj == 2 ]; then
  thresh=$(echo $thresh | awk '{print $1 / 3}')
fi
done ## while
#------------------ FIM DO LOP ------------------

dmcopy "${obsid}_rprofile_rmid.fits[rmid < $rextPHY]" ${obsid}_rprofile_rmid_source.fits

dmstat "$blabla[col RMID][NBG=0:$thresh]" verbose=0
rbkg=$(pget dmstat out_max)

#-----Região da fonte extensa----
echo "annulus($xcen,$ycen,$ri,$rextPHY)" > source.reg

#-----Região do background------
echo "annulus($xcen,$ycen,$rextPHY,$rbkg)" > bkg.reg

echo "Foi definido a região do background entre "$rext" e "$rend" segundos de arco"

dmstat "$rp[cols rmid][rmid<$rextPHY]" data verbose=0
ncir_s=$(pget dmstat out_good);
#---------Definindo Anéis concentricos----------
# Numero de aneis
ra=$ri
jj=1
while [ $jj -le $ncir_s ]; do
  rb=$(echo $ri $jj | awk '{print $1*(1.05)^($2)}')
  echo "annulus($xcen,$ycen,$ra,$rb)" >> fatia.reg
  ra=$rb
  jj=$(($jj + 1))
done

punlearn dmextract
pset dmextract infile="$fimg[bin sky=@fatia.reg]"
pset dmextract outfile=${obsid}_rprofile_source.fits
pset dmextract bkg="${blk}[bin sky=@fatia.reg]"
pset dmextract exp=${emap}
pset dmextract bkgnorm=$bgscale
pset dmextract bkgexp=${emap}
pset dmextract opt=generic
dmextract mode=h clob+

# ds9 $fimg -scale log -scale limits 0 10 -region bkg.reg -smooth -cmap b -zoom to fit -saveimage source_bkg.png


if [ $quieto ==  1 ]; then
   ds9 $fimg -scale log -regions -format ciao bkg.reg -smooth -zoom to fit -saveimage source_bkg.png -cmap load $ASCDS_CONTRIB/data/purple4.lut &
fi


echo "Imagem da fonte e do background: source_bkg.png"



#
# # B) Critério de Johnny
# punlearn dmstat
# dmstat "${obsid}_rprofile_rmid.fits[col NET_RATE]"
#
# # Define a média, sigma e o intervalo +/- 0.5 sigma
# emean=$(pget dmstat out_mean); sigma=$(pget dmstat out_sigma)
# min=$(echo $emean $sigma | awk '{print ($1 - 1 * $2)}')
# max=$(pget dmstat out_max)
#
# dmstat "${obsid}_rprofile_rmid.fits[col RMID][NET_RATE=${min}:${max}]" verbose=$quieto
# rextPHY=$(pget dmstat out_max)
#
# rext=$(echo $rextPHY $pixscale | awk '{print ($1 * $2)}')
#
# echo "O raio externo dentro de 1 sigma da emissão é:" $rext " segundos de arco"



# background normaliado
# dmstat "$bla[col NBG]" verbose=0
# mean=$(pget dmstat out_mean);sigma=$(pget dmstat out_sigma); thresh=$(echo $sigma | awk '{print (0.5 * $1)}')

# punlearn dmtcalc
# pset dmtcalc infile=$bla
# pset dmtcalc outfile=$blabla
# pset dmtcalc expression="BG=(NBG-3)"
# dmtcalc mode=h
