#!/bin/bash

# moontextures.sh - a script to convert LROC sattelite images into textures
# for use with FGearthview (orbital rendering)
# Author: Chris Ringeval <eatdirt@mageia.org>
# Based on convert.sh by chris_blues <chris@musicchris.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
# v0.1: Chris Ringeval (eatdirt):
# - support for topographic and relief shading map to create moon and
# - normalmap textures
#

VERSION="v0.1"

# make sure the script halts on error
set -e

function showHelp
  {
   echo "Moontextures converter script $VERSION"
   echo "https://github.com/eatdirt/LROC2FGearthview"
   echo
   echo "Usage:"
   echo "./moontextures.sh [ download moon heights"
   echo "               1k 2k 4k 8k 16k cleanup ]"
   echo
   echo "* Append \"download\" to the command to force the download"
   echo "  process alltogether. Only makes sense if you have not already got"
   echo "  the necessary data."
   echo "Examples:"
   echo "./moontextures.sh moon heihgts"
   echo "Will generate all textures needed for EarthView"
   echo
   echo "./moontextures.sh moon 4k"
   echo "Will generate only tiles of the moon of 4096x4096 size."
   exit 1
  }
if [ -z $1 ] ; then showHelp ; fi
if [ $1 == "--help" ] ; then showHelp ; fi
if [ $1 == "-h" ] ; then showHelp ; fi

################################
## Get command line arguments ##
################################
for ARG in "$@"
do
    if [ $ARG == "download" ] ; then
	DOWNLOAD="true" ; echo "Requesting download!"
    else
	DOWNLOAD="false"
    fi
  if [ $ARG == "heights" ] ; then HEIGHTS="true" ; fi
  if [ $ARG == "moon" ] ; then MOON="true" ; fi
  if [ $ARG == "all" ] ; then HEIGHTS="true" ; MOON="true" ; fi
  if [ $ARG == "1k" ] ; then RESOLUTION="1024" ; fi
  if [ $ARG == "2k" ] ; then RESOLUTION="2048" ; fi
  if [ $ARG == "4k" ] ; then RESOLUTION="4096" ; fi
  if [ $ARG == "8k" ] ; then RESOLUTION="8192" ; fi
  if [ $ARG == "16k" ] ; then RESOLUTION="16384" ; fi
  if [ $ARG == "cleanup" ] ; then CLEANUP="true" ; fi
  if [ $ARG == "mosaic" ] ; then MOSAIC="true" ; fi
done
if [ -z $HEIGHTS ] ; then HEIGHTS="false" ; fi
if [ -z $MOON ] ; then MOON="false" ; fi
if [ -z $CLEANUP ] ; then CLEANUP="false" ; fi
if [ -z $MOSAIC ] ; then MOSAIC="false" ; fi


########################
## Set some variables ##
########################

DL_LOCATION="LROC"

#allows for using an alternate download method (default to wget)
#DL_METHOD="CURL"
DL_METHOD="WGET"

#if you have a lot of RAM, increasing this, for instance to 64GiB,
#gives a huge speed-up
MEM_LIMIT=32GiB

#border width (should match the ac3 file, don't change unless you know
#what you're doing)
#FORCE_BORDER_WIDTH=0
BORDER_WIDTH_FACTOR=128

#more info here: https://imagemagick.org/Usage/filter/nicolas/
#very long
#RESIZE_METHOD="-filter LanczosSharp +remap -distort Resize"
#STRETCH_METHOD="-resize"


#faster
RESIZE_METHOD="-resize"
STRETCH_METHOD="-resize"



mkdir -p tmp
export MAGICK_TMPDIR=${PWD}/tmp
echo "tmp-dir: $MAGICK_TMPDIR"

mkdir -p logs
TIME=$(date +"%Y-%m-%d_%H:%M:%S")
LOGFILE_GENERAL="logs/${TIME}.log"
LOGFILE_TIME="logs/${TIME}.time.log"

#command line gimp plugin from https://github.com/eatdust/normalmap
#higher filters (5x5) create to sharp features. We also put in the alpha
#channel the inverse_height
NORMALBIN="normalmap"
NORMALOPTS="-s 1 -f FILTER_PREWITT_3x3 -a ALPHA_INVERSE_HEIGHT"


#we need gdal to reproject polar stereographics to equirectangular
GDALWARPBIN="gdalwarp"
GDALWARPOPTS="-t_srs EPSG:4326 -r bilinear -overwrite"

URLS_MOON_304P="lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_P900N0000_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300N2250_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300N3150_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300N0450_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300N1350_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300S2250_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300S3150_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300S0450_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_E300S1350_304P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_EMP_NORMALIZED/WAC_EMP_643NM_P900S0000_304P.TIF"

URLS_MOON_100M="lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_P900N0000_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300N2250_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300N3150_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300N0450_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300N1350_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300S2250_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300S3150_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300S0450_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_E300S1350_100M.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLOBAL/WAC_GLOBAL_P900S0000_100M.TIF"


URLS_HEIGHTS_256P="lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_P900N0000_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300N2250_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300N3150_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300N0450_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300N1350_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300S2250_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300S3150_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300S0450_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_E300S1350_256P.TIF
lroc.sese.asu.edu/data/LRO-L-LROC-5-RDR-V1.0/LROLRC_2001/EXTRAS/BROWSE/WAC_GLD100/WAC_GLD100_P900S0000_256P.TIF"

#contaminated by shadows :(
URLS_MOON=${URLS_MOON_100M}
IDMOON_E="GLOBAL_E300"
IDMOON_P="GLOBAL_P900"
RESMOON="100M"

#they miss the polar caps
#URLS_MOON=${URLS_MOON_304P}
#IDMOON_E="EMP_643NM_E300"
#IDMOON_P="EMP_643NM_P900"
#RESMOON="304P"

URLS_HEIGHTS=${URLS_HEIGHTS_256P}
IDHEIGHTS_E="GLD100_E300"
IDHEIGHTS_P="GLD100_P900"
RESHEIGHTS="256P"



if ! [ -x "$(command -v $NORMALBIN)" ]
  then
    if ! [ -x "./${NORMALBIN}" ]
      then
        echo ">>>>>>>>>>>>  Error: $NORMALBIN binary not found! <<<<<<<<<<<<<"
        echo "You can get it from: https://github.com/eatdust/normalmap"
        HEIGHTS="false"
      else
        NORMALBIN="./${NORMALBIN}"
    fi
fi


if ! [ -x "$(command -v $GDALWARPBIN)" ]
  then
    if ! [ -x "./${GDALWARPBIN}" ]
      then
        echo ">>>>>>>>>>>>  Error: $GDALWARPBIN binary not found! <<<<<<<<<<<<<"
	exit 0;
      else
        GDALWARPBIN="./${GDALWARPBIN}"
    fi
fi


if [ -z $RESOLUTION ]
  then
    RESOLUTION="1024
2048
4096
8192
16384"
    NO_RESOLUTION_GIVEN="false"
    RESOLUTION_MAX="16384"
fi
if [ -z $RESOLUTION_MAX ] ; then RESOLUTION_MAX=$RESOLUTION ; fi

LROC_N="N0000"
LROC_S="S0000"

LROC_E="N2250
N3150
N0450
N1350
S2250
S3150
S0450
S1350"

IM="0
1
2
3
4
5
6
7"

TILES="N1
N2
N3
N4
S1
S2
S3
S4"

BORDERS="top
right
bottom
left"


#################
##  FUNCTIONS  ##
#################

function cleanUp
  {
   echo
   echo "############################"
   echo "## Removing all tmp-files ##"
   echo "############################"
   rm -rvf tmp/moon*
   rm -rvf tmp/moonheight*
   rm -rvf tmp/uncap*
   rm -rvf tmp/polarcap*
  }

function prettyTime
  {
   if [ $SECS -gt 60 ]
     then let "MINUTES = $SECS / 60"
     else MINUTES=0
   fi
   if [ $MINUTES -gt 60 ]
     then let "HOURS = $MINUTES / 60"
     else HOURS=0
   fi
   if [ $HOURS -gt 24 ]
     then let "DAYS = $HOURS / 24"
     else DAYS=0
   fi
   if [ $DAYS -gt 0 ] ; then let "HOURS = $HOURS - ( $DAYS * 24 )" ; fi
   if [ $HOURS -gt 0 ] ; then let "MINUTES = $MINUTES - ( ( ( $DAYS * 24 ) + $HOURS ) * 60 )" ; fi
   if [ $MINUTES -gt 0 ] ; then let "SECS = $SECS - ( ( ( ( ( $DAYS * 24 ) + $HOURS ) * 60 ) + $MINUTES ) * 60 )" ; fi
  }

function getProcessingTime
  {
   ENDTIME=$(date +%s)
   if [ $LASTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $LASTTIME"
   fi
   prettyTime
   OUTPUTSTRING="${SECS}s"
   if [ $MINUTES -gt 0 ] ; then OUTPUTSTRING="${MINUTES}m ${SECS}s" ; fi
   if [ $HOURS -gt 0 ] ; then OUTPUTSTRING="${HOURS}h ${MINUTES}m ${SECS}s" ; fi
   if [ $DAYS -gt 0 ] ; then OUTPUTSTRING="${DAYS}d ${HOURS}h ${MINUTES}m ${SECS}s" ; fi
   echo "Processing time: $OUTPUTSTRING" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   LASTTIME=$ENDTIME
  }


function IM2FG
  {
   if [ $1 == "0" ] ; then DEST="N1" ; fi
   if [ $1 == "1" ] ; then DEST="N2" ; fi
   if [ $1 == "2" ] ; then DEST="N3" ; fi
   if [ $1 == "3" ] ; then DEST="N4" ; fi
   if [ $1 == "4" ] ; then DEST="S1" ; fi
   if [ $1 == "5" ] ; then DEST="S2" ; fi
   if [ $1 == "6" ] ; then DEST="S3" ; fi
   if [ $1 == "7" ] ; then DEST="S4" ; fi
  }

function LROC2FG
  {
   if [ $1 == "N2250" ] ; then DEST="N1" ; fi
   if [ $1 == "N3150" ] ; then DEST="N2" ; fi
   if [ $1 == "N0450" ] ; then DEST="N3" ; fi
   if [ $1 == "N1350" ] ; then DEST="N4" ; fi
   if [ $1 == "S2250" ] ; then DEST="S1" ; fi
   if [ $1 == "S3150" ] ; then DEST="S2" ; fi
   if [ $1 == "S0450" ] ; then DEST="S3" ; fi
   if [ $1 == "S1350" ] ; then DEST="S4" ; fi
  }

function LROC2TE
#59.995797
#89.997675
{
   if [ $1 == "N2250" ] ; then GDAL_TE="-te -180 60 -90 90" ; fi
   if [ $1 == "N3150" ] ; then GDAL_TE="-te -90 60 0 90" ; fi
   if [ $1 == "N0450" ] ; then GDAL_TE="-te 0 60 90 90" ; fi
   if [ $1 == "N1350" ] ; then GDAL_TE="-te 90 60 180 90" ; fi
   if [ $1 == "S2250" ] ; then GDAL_TE="-te -180 -90 -90 -60" ; fi
   if [ $1 == "S3150" ] ; then GDAL_TE="-te -90 -90 0 -60" ; fi
   if [ $1 == "S0450" ] ; then GDAL_TE="-te 0 -90 90 -60" ; fi
   if [ $1 == "S1350" ] ; then GDAL_TE="-te 90 -90 180 -60" ; fi
  }

  function LROC2P
  {
   if [ $1 == "N2250" ] ; then LROC_P=$LROC_N ; fi
   if [ $1 == "N3150" ] ; then LROC_P=$LROC_N ; fi
   if [ $1 == "N0450" ] ; then LROC_P=$LROC_N ; fi
   if [ $1 == "N1350" ] ; then LROC_P=$LROC_N ; fi
   if [ $1 == "S2250" ] ; then LROC_P=$LROC_S ; fi
   if [ $1 == "S3150" ] ; then LROC_P=$LROC_S ; fi
   if [ $1 == "S0450" ] ; then LROC_P=$LROC_S ; fi
   if [ $1 == "S1350" ] ; then LROC_P=$LROC_S ; fi
   }


  
  
function downloadImages
  {
   echo | tee -a $LOGFILE_GENERAL
   echo "###################################################" | tee -a $LOGFILE_GENERAL
   if [ -z $DL_LOCATION ]
   then
       DL_LOCATION="LROC"
   fi

   if [ $DL_LOCATION == "LROC" ]
   then
       echo "## Downloading images from lroc.sese.asu.edu ##" | tee -a $LOGFILE_GENERAL
   fi

   echo "###################################################" | tee -a $LOGFILE_GENERAL

   if [ $MOON == "true" ]
   then
     if [ $DL_LOCATION == "LROC" ]
     then
       downloadMoon
     fi
   fi

   if [ $HEIGHTS == "true" ]
   then
     if [ $DL_LOCATION == "LROC" ]
     then
       downloadHeights
     fi
   fi
  }

function downloadMoon
  {
   mkdir -p input
   echo "Downloading moon tiles..." | tee -a $LOGFILE_GENERAL
   for f in $URLS_MOON
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     echo
     echo "downloading $FILENAME..." | tee -a $LOGFILE_GENERAL
     sleep $[ ( $RANDOM % 10 )  + 1 ]s
     if [ $DL_METHOD == "CURL" ]; then
	 curl --progress-bar -C - --output ./input/$FILENAME -O $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     else
	 wget --wait=10 --random-wait --output-document=input/$FILENAME \
	      --continue --show-progress $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     fi
   done
  }


function downloadHeights
  {
   mkdir -p input
   echo "Downloading height tiles..." | tee -a $LOGFILE_GENERAL
   for f in $URLS_HEIGHTS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     echo
     echo "downloading $FILENAME..." | tee -a $LOGFILE_GENERAL
     sleep $[ ( $RANDOM % 10 )  + 1 ]s
     if [ $DL_METHOD == "CURL" ]; then
	 curl --progress-bar -C - --output ./input/$FILENAME -O $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     else
	 wget --wait=10 --random-wait --output-document=input/$FILENAME \
	      --continue --show-progress $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     fi     
   done
  }



function generateMoon
  {

   STARTTIME=$(date +%s)
   echo | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo "####    Processing Moon    ####" | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
#this settings are local to earch generateXXXX
   if [ -z $FORCE_BORDER_WIDTH ]; then
       let "BORDER_WIDTH = $RESOLUTION_MAX / $BORDER_WIDTH_FACTOR"
   else
       BORDER_WIDTH=$FORCE_BORDER_WIDTH
   fi
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - 1"
   
   mkdir -p tmp
   mkdir -p output


   LASTTIME=$STARTTIME
   echo | tee -a $LOGFILE_GENERAL
   echo "##############################" | tee -a $LOGFILE_GENERAL
   echo "##  Prepare moon textures  ##" | tee -a $LOGFILE_GENERAL
   echo "##############################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   echo "## Resize the LROC-Originals to ${RESOLUTION_MAX}-(2*${BORDER_WIDTH}) ##" | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   for t in $LROC_E
   do
     LROC2FG $t
     LROC2P $t
     LROC2TE $t

     FOUND_BIGGER_MOON_PICTURE="false"
     unset TIMESAVER_SIZE
     if [ ! -s "tmp/moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" ]
     then
       {
        for r in 16384 8192 4096 2048
        do
          if [ $r -le $RESOLUTION_MAX ]
          then
            continue
          fi
          let "IMAGE_SIZE = $r - ( 2 * ( $r / $BORDER_WIDTH_FACTOR ) )"
          let "I_W = $IMAGE_SIZE * 4"
          let "I_H = $IMAGE_SIZE * 2"
          if [ -s tmp/moon_seamless_${IMAGE_SIZE}_${DEST}.mpc ]
          then
            if [ $IMAGE_SIZE -ge $IMAGE_BORDERLESS ]
            then
              FOUND_BIGGER_MOON_PICTURE="true"
              TIMESAVER_SIZE="$IMAGE_SIZE"
            fi
          fi
        done
        if [ $FOUND_BIGGER_MOON_PICTURE != "true" ]
        then

	    $GDALWARPBIN ${GDALWARPOPTS} ${GDAL_TE} \
			 input/WAC_${IDMOON_P}${LROC_P}_${RESMOON}.TIF \
			 tmp/polarcap_moon_${DEST}.tif	    
	    
	    convert -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		    tmp/polarcap_moon_${DEST}.tif ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
	            tmp/polarcap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    
	    convert -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		    input/WAC_${IDMOON_E}${t}_${RESMOON}.TIF ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
	            tmp/uncap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc

	    if [[ ${LROC_P} == ${LROC_N} ]]; then
		montage -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
			tmp/polarcap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			tmp/uncap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			-tile 1x2 -geometry +0+0 ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
			tmp/glued_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    fi

	    if [[ ${LROC_P} == ${LROC_S} ]]; then
		montage -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
			tmp/uncap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			tmp/polarcap_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			-tile 1x2 -geometry +0+0  ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
			tmp/glued_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    fi
	    
	    convert  -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		     tmp/glued_moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
		     ${STRETCH_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS}\! \
		     tmp/moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    
            set +x
        else
          echo "==> Timesaver:) Using existing file: tmp/moon_seamless_${TIMESAVER_SIZE}_${DEST}.mpc -> tmp/moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL
          set -x
          convert \
            -monitor \
            -limit memory ${MEM_LIMIT} \
            -limit map ${MEM_LIMIT} \
             tmp/moon_seamless_${TIMESAVER_SIZE}_${DEST}.mpc \
            ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
             tmp/moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
          set +x
        fi
       }
     else echo "=> Skipping existing file: tmp/moon_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 3h, 12m, 9s
   echo "input/WAC_${IDMOON}.png -> tmp/moon_seamless_${IMAGE_BORDERLESS}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   if [[ ${BORDER_WIDTH} -ge 1 ]]; then
       
       echo | tee -a $LOGFILE_GENERAL
       echo "#####################################" | tee -a $LOGFILE_GENERAL
       echo "## Put a ${BORDER_WIDTH}px border to each side ##" | tee -a $LOGFILE_GENERAL
       echo "#####################################" | tee -a $LOGFILE_GENERAL
       for t in $TILES
       do
	   if [ ! -s "tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
	   then
	       # set -x
	       convert \
		   -monitor \
		   tmp/moon_seamless_${IMAGE_BORDERLESS}_${t}.mpc \
		   -bordercolor none \
		   -border ${BORDER_WIDTH} \
		   tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc
	       set +x
	       echo
	   fi
	   if [ ! -s "tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc" ]
	   then
	       # set -x
	       cp tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc
	       cp tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/moon_seams_${RESOLUTION_MAX}_${t}.cache
	       set +x
	   else echo "=> Skipping existing file: tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
	   fi
       done
       # 11m, 24s
       echo "-> tmp/moon_seams_${RESOLUTION_MAX}_[NS][1-4]_emptyBorder.mpc -> tmp/moon_seams_${RESOLUTION_MAX}_[NS][1-4].mpc" >> $LOGFILE_TIME
       getProcessingTime

       echo | tee -a $LOGFILE_GENERAL
       echo "######################################################" | tee -a $LOGFILE_GENERAL
       echo "## crop borderline pixels and propagate to the edge ##" | tee -a $LOGFILE_GENERAL
       echo "######################################################" | tee -a $LOGFILE_GENERAL

       CROP_TOP="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_RIGHT="1x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
       CROP_BOTTOM="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
       CROP_LEFT="1x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
       CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
       CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"

       ## HORIZ meaning a horizontal bar, like the one on top
       HORIZ_RESIZE="${IMAGE_BORDERLESS}x${BORDER_WIDTH}"
       VERT_RESIZE="${BORDER_WIDTH}x${IMAGE_BORDERLESS}"

       POS_TOP="+${BORDER_WIDTH}+0"
       POS_RIGHT="+${IMAGE_WITH_BORDER_POS}+${BORDER_WIDTH}"
       POS_BOTTOM="+${BORDER_WIDTH}+${IMAGE_WITH_BORDER_POS}"
       POS_LEFT="+0+${BORDER_WIDTH}"

       for t in $TILES
       do
	   if [ ! -s "tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc" ]
	   then
	       for b in $BORDERS
	       do
		   {
		       if [ $b == "top" ]
		       then
			   CROP=$CROP_TOP
			   RESIZE=$HORIZ_RESIZE
			   POSITION=$POS_TOP
			   CROPCORNER=$CROP_TOPRIGHT
			   CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
			   CORNER_NAME="topRight"
		       fi
		       if [ $b == "right" ]
		       then
			   CROP=$CROP_RIGHT
			   RESIZE=$VERT_RESIZE
			   POSITION=$POS_RIGHT
			   CROPCORNER=$CROP_BOTTOMRIGHT
			   CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
			   CORNER_NAME="bottomRight"
		       fi
		       if [ $b == "bottom" ]
		       then
			   CROP=$CROP_BOTTOM
			   RESIZE=$HORIZ_RESIZE
			   POSITION=$POS_BOTTOM
			   CROPCORNER=$CROP_BOTTOMLEFT
			   CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
			   CORNER_NAME="bottomLeft"
		       fi
		       if [ $b == "left" ]
		       then
			   CROP=$CROP_LEFT
			   RESIZE=$VERT_RESIZE
			   POSITION=$POS_LEFT
			   CROPCORNER=$CROP_TOPLEFT
			   CORNER_POS="+0+0"
			   CORNER_NAME="topLeft"
		       fi
		       echo
		       # set -x
		       convert \
			   -monitor \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
			   -crop $CROP \
			   ${STRETCH_METHOD} $RESIZE\! \
			   tmp/moon_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
		       convert \
			   -monitor \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
			   -crop $CROPCORNER \
			   ${STRETCH_METHOD} ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
			   tmp/moon_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc
		       convert \
			   -monitor \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc \
			   tmp/moon_${RESOLUTION_MAX}_${t}_seam_${b}.mpc \
			   -geometry $POSITION \
			   -composite \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc
		       echo
		       convert \
			   -monitor \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc \
			   tmp/moon_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc \
			   -geometry $CORNER_POS \
			   -composite \
			   tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc
		       set +x
		       echo
		   }
	       done
	       echo
	       # set -x
	       cp -v tmp/moon_seams_${RESOLUTION_MAX}_${t}.mpc tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
	       cp -v tmp/moon_seams_${RESOLUTION_MAX}_${t}.cache tmp/moon_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
	       set +x

	   else echo "=> Skipping existing file: tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
	   fi

       done
       # 37m, 6s
       echo "-> tmp/moon_seams_${RESOLUTION_MAX}_[NS][1-4].mpc -> tmp/moon_${RESOLUTION_MAX}_done_[NS][1-4].mpc" >> $LOGFILE_TIME
       getProcessingTime

   else
       for t in $TILES
       do
	   cp -v tmp/moon_seamless_${RESOLUTION_MAX}_${t}.mpc tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
	   cp -v tmp/moon_seamless_${RESOLUTION_MAX}_${t}.cache tmp/moon_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
       done
   fi
       
  for t in $TILES
   do
     echo | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     echo "## Final output of tile $t ##" | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/moon_${t}.dds @ ${r}x${r}"
        # set -x

        if [ ! -s "output/${r}/moon_${t}.dds" ]
        then

          convert \
            -monitor \
             tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
            -flip \
            -define dds:compression=dxt5 \
             output/${r}/moon_${t}.dds
          set +x
          echo

        else echo "=> Skipping existing file: output/${r}/moon_${t}.dds" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        echo "--> Writing output/${r}/moon_${t}.png @ ${r}x${r}"

        if [ ! -s "output/${r}/moon_${t}.png" ]
        then

          # set -x
          convert \
            -monitor \
             tmp/moon_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
             output/${r}/moon_${t}.png
          set +x
          echo

        else echo "=> Skipping existing file: output/${r}/moon_${t}.png" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME

        fi
       }
     done

     echo | tee -a $LOGFILE_GENERAL
     echo "Moon $t [ done ]" | tee -a $LOGFILE_GENERAL
     echo | tee -a $LOGFILE_GENERAL

   done
   echo "###############################" | tee -a $LOGFILE_GENERAL
   echo "####    Moon: [ done ]    ####" | tee -a $LOGFILE_GENERAL
   echo "###############################" | tee -a $LOGFILE_GENERAL
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   echo "-> output/<\$RESOLUTIONS>/moon_[NS][1-4].png" >> $LOGFILE_TIME
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a $LOGFILE_GENERAL
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a $LOGFILE_GENERAL
  }



function generateMoonHeights
  {
  if [ -z $STARTTIME ] ; then STARTTIME=$(date +%s) ; fi
   echo | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo "### Processing Moon Heights  ###" | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
   if [ -z $FORCE_BORDER_WIDTH ]; then
       let "BORDER_WIDTH = $RESOLUTION_MAX / $BORDER_WIDTH_FACTOR"
   else
       BORDER_WIDTH=$FORCE_BORDER_WIDTH
   fi
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - 1"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   mkdir -p tmp
   mkdir -p output


   echo "################################################" | tee -a $LOGFILE_GENERAL
   echo "## Resize the LROC-Originals to ${RESOLUTION_MAX}-(2*${BORDER_WIDTH}) ##" | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   for t in $LROC_E
   do
     LROC2FG $t
     LROC2P $t
     LROC2TE $t
     
     FOUND_BIGGER_WORLD_PICTURE="false"
     unset TIMESAVER_SIZE
     if [ ! -s "tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" ]
     then
       {
        for r in $RESOLUTION
        do
          if [ $r -le $RESOLUTION_MAX ]
          then
            continue
          fi
          let "IMAGE_SIZE = $r - ( 2 * ( $r / $BORDER_WIDTH_FACTOR ) )"
          let "I_W = $IMAGE_SIZE * 4"
          let "I_H = $IMAGE_SIZE * 2"
          if [ -s tmp/moonheights_seamless_${IMAGE_SIZE}_${DEST}.mpc ]
          then
            if [ $IMAGE_SIZE -ge $IMAGE_BORDERLESS ]
            then
              FOUND_BIGGER_WORLD_PICTURE="true"
              TIMESAVER_SIZE="$IMAGE_SIZE"
            fi
          fi
        done
        if [ $FOUND_BIGGER_WORLD_PICTURE != "true" ]
        then

	    $GDALWARPBIN ${GDALWARPOPTS} ${GDAL_TE} \
			 input/WAC_${IDHEIGHTS_P}${LROC_P}_${RESHEIGHTS}.TIF \
			 tmp/polarcap_moonheights_${DEST}.tif	    
	    	    
	    convert -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		    tmp/polarcap_moonheights_${DEST}.tif ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
	            tmp/polarcap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    
	    convert -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		    input/WAC_${IDHEIGHTS_E}${t}_${RESHEIGHTS}.TIF ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
	            tmp/uncap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc

	    if [[ ${LROC_P} == ${LROC_N} ]]; then
		montage -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
			tmp/polarcap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			tmp/uncap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			-tile 1x2 -geometry +0+0 ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
			tmp/glued_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    fi

	    if [[ ${LROC_P} == ${LROC_S} ]]; then
		montage -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
			tmp/uncap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			tmp/polarcap_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
			-tile 1x2 -geometry +0+0  ${RESIZE_METHOD} ${IMAGE_BORDERLESS} \
			tmp/glued_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    fi
	    
	    convert  -monitor -limit memory ${MEM_LIMIT} -limit map ${MEM_LIMIT} \
		     tmp/glued_moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc \
		     ${STRETCH_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS}\! \
		     tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	    
	    
	    
            set +x
	    
        else
          echo "==> Timesaver:) Using existing file: tmp/moonheights_seamless_${TIMESAVER_SIZE}_${DEST}.mpc -> tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL
           set -x
          convert \
            -monitor \
            -limit memory ${MEM_LIMIT} \
            -limit map ${MEM_LIMIT} \
            tmp/moonheights_seamless_${TIMESAVER_SIZE}_${DEST}.mpc \
            ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
            tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
          set +x
        fi
       }
     else echo "=> Skipping existing file: tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 3h, 12m, 9s
   if [ -z $LASTTIME ] ; then LASTTIME=$STARTTIME ; fi
   echo "input/gebco_08_rev_elev_[A-D][12]_grey_geo.tif -> tmp/moonheights_seamless_${IMAGE_BORDERLESS}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   if [[ ${BORDER_WIDTH} -ge 1 ]]; then
   
       echo | tee -a $LOGFILE_GENERAL
       echo "#####################################" | tee -a $LOGFILE_GENERAL
       echo "## Put a ${BORDER_WIDTH}px border to each side ##" | tee -a $LOGFILE_GENERAL
       echo "#####################################" | tee -a $LOGFILE_GENERAL
       for t in $TILES
       do
	   if [ ! -s "tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
	   then
	       # set -x
	       convert \
		   -monitor \
		   tmp/moonheights_seamless_${IMAGE_BORDERLESS}_${t}.mpc \
		   -bordercolor none \
		   -border ${BORDER_WIDTH} \
		   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc
	       set +x
	       echo
	   fi
	   if [ ! -s "tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc" ]
	   then
	       # set -x
	       cp tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc
	       cp tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.cache
	       set +x
	   else echo "=> Skipping existing file: tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
	   fi
       done
       # 11m, 24s
       echo "-> tmp/moonheights_seams_${RESOLUTION_MAX}_[NS][1-4]_emptyBorder.mpc -> tmp/moonheights_seams_${RESOLUTION_MAX}_[NS][1-4].mpc" >> $LOGFILE_TIME
       getProcessingTime
       
       
       echo | tee -a $LOGFILE_GENERAL
       echo "######################################################" | tee -a $LOGFILE_GENERAL
       echo "## crop borderline pixels and propagate to the edge ##" | tee -a $LOGFILE_GENERAL
       echo "######################################################" | tee -a $LOGFILE_GENERAL

       CROP_TOP="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_RIGHT="1x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
       CROP_BOTTOM="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
       CROP_LEFT="1x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
       CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
       CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
       CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"

       ## HORIZ meaning a horizontal bar, like the one on top
       HORIZ_RESIZE="${IMAGE_BORDERLESS}x${BORDER_WIDTH}"
       VERT_RESIZE="${BORDER_WIDTH}x${IMAGE_BORDERLESS}"

       POS_TOP="+${BORDER_WIDTH}+0"
       POS_RIGHT="+${IMAGE_WITH_BORDER_POS}+${BORDER_WIDTH}"
       POS_BOTTOM="+${BORDER_WIDTH}+${IMAGE_WITH_BORDER_POS}"
       POS_LEFT="+0+${BORDER_WIDTH}"

       for t in $TILES
       do
	   if [ ! -s "tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc" ]
	   then
	       for b in $BORDERS
	       do
		   {
		       if [ $b == "top" ]
		       then
			   CROP=$CROP_TOP
			   RESIZE=$HORIZ_RESIZE
			   POSITION=$POS_TOP
			   CROPCORNER=$CROP_TOPRIGHT
			   CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
			   CORNER_NAME="topRight"
		       fi
		       if [ $b == "right" ]
		       then
			   CROP=$CROP_RIGHT
			   RESIZE=$VERT_RESIZE
			   POSITION=$POS_RIGHT
			   CROPCORNER=$CROP_BOTTOMRIGHT
			   CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
			   CORNER_NAME="bottomRight"
		       fi
		       if [ $b == "bottom" ]
		       then
			   CROP=$CROP_BOTTOM
			   RESIZE=$HORIZ_RESIZE
			   POSITION=$POS_BOTTOM
			   CROPCORNER=$CROP_BOTTOMLEFT
			   CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
			   CORNER_NAME="bottomLeft"
		       fi
		       if [ $b == "left" ]
		       then
			   CROP=$CROP_LEFT
			   RESIZE=$VERT_RESIZE
			   POSITION=$POS_LEFT
			   CROPCORNER=$CROP_TOPLEFT
			   CORNER_POS="+0+0"
			   CORNER_NAME="topLeft"
		       fi
		       echo
		       # set -x
		       convert \
			   -monitor \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
			   -crop $CROP \
			   ${STRETCH_METHOD} $RESIZE\! \
			   tmp/moonheights_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
		       convert \
			   -monitor \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
			   -crop $CROPCORNER \
			   ${STRETCH_METHOD} ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
			   tmp/moonheights_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc
		       convert \
			   -monitor \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc \
			   tmp/moonheights_${RESOLUTION_MAX}_${t}_seam_${b}.mpc \
			   -geometry $POSITION \
			   -composite \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc
		       echo
		       convert \
			   -monitor \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc \
			   tmp/moonheights_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc \
			   -geometry $CORNER_POS \
			   -composite \
			   tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc
		       set +x
		       echo
		   }
	       done
	       echo
	       # set -x
	       cp -v tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.mpc tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
	       cp -v tmp/moonheights_seams_${RESOLUTION_MAX}_${t}.cache tmp/moonheights_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
	       set +x

	   else echo "=> Skipping existing file: tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
	   fi

       done
       # 37m, 6s
       echo "-> tmp/moonheights_seams_${RESOLUTION_MAX}_[NS][1-4].mpc -> tmp/moonheights_${RESOLUTION_MAX}_done_[NS][1-4].mpc" >> $LOGFILE_TIME
       getProcessingTime
   else
       for t in $TILES
       do
	   cp -v tmp/moonheights_seamless_${RESOLUTION_MAX}_${t}.mpc tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
	   cp -v tmp/moonheights_seamless_${RESOLUTION_MAX}_${t}.cache tmp/moonheights_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
       done
   fi
   

       
  for t in $TILES
   do
     echo | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     echo "## Final output of tile $t ##" | tee -a $LOGFILE_GENERAL
     echo "##       and normalmapping ##" | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL

     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        set +x
        echo
        echo "--> Writing output/${r}/moonheights_${t}.png @ ${r}x${r}"
        # set -x

        if [ ! -s "output/${r}/moonheights_${t}.png" ]
        then

          convert \
            -monitor \
             tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
             output/${r}/moonheights_${t}.png
          echo

        else echo "=> Skipping existing file: tmp/moonheights_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        echo "--> Writing output/${r}/normalmap_moon_${t}.png @ ${r}x${r}"
        if [ ! -s "output/${r}/normalmap_moon_${t}.png" ]
        then

          $NORMALBIN $NORMALOPTS output/${r}/moonheights_${t}.png output/${r}/normalmap_moon_${t}.png

        else echo "=> Skipping existing file: output/${r}/normalmap_moon_${t}.png" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        set +x
        echo
       }
     done

     echo | tee -a $LOGFILE_GENERAL
     echo "Moonheights and Normal $t [ done ]" | tee -a $LOGFILE_GENERAL
     echo | tee -a $LOGFILE_GENERAL

   done
   echo "###############################" | tee -a $LOGFILE_GENERAL
   echo "####    Moonheights: [ done ]  ####" | tee -a $LOGFILE_GENERAL
   echo "###############################" | tee -a $LOGFILE_GENERAL
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   echo "-> output/<\$RESOLUTIONS>/moonheights_[NS][1-4].png" >> $LOGFILE_TIME
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a $LOGFILE_GENERAL
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a $LOGFILE_GENERAL
  }




function generateMosaic
  {
   echo | tee -a $LOGFILE_GENERAL
   echo "##############################################" | tee -a $LOGFILE_GENERAL
   echo "##  Creating a mosaic of the created tiles  ##" | tee -a $LOGFILE_GENERAL
   echo "##############################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL


   if [ -z $FORCE_BORDER_WIDTH ]; then
       let "BORDER_WIDTH = $RESOLUTION_MAX / $BORDER_WIDTH_FACTOR"
   else
       BORDER_WIDTH=$FORCE_BORDER_WIDTH
   fi
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   
   RES=${IMAGE_BORDERLESS}

   let "WIDTH = 4 * $RES"
   let "HEIGHT = 2 * $RES"
   echo "Mosaic generation at resolution: $RES" | tee -a $LOGFILE_GENERAL

   if [[ $HEIGHTS == "true" ]]
   then
     {
	 montage tmp/moonheights_seamless_${RES}_N[1234].mpc tmp/moonheights_seamless_${RES}_S[1234].mpc \
		 -geometry +0 -tile 4x2 output/${RESOLUTION_MAX}/fullmoonheights.png

	 $NORMALBIN $NORMALOPTS output/${RESOLUTION_MAX}/fullmoonheights.png output/${RESOLUTION_MAX}/normalmap_fullmoon.png
	 
     }
   fi

   if [[ $MOON == "true" ]]
   then
     {
	 montage tmp/moon_seamless_${RES}_N[1234].mpc tmp/moon_seamless_${RES}_S[1234].mpc \
		 -geometry +0 -tile 4x2 output/${RESOLUTION_MAX}/fullmoon.png
     }
   fi
  }



###############################
####    Actual program:    ####
###############################

echo | tee $LOGFILE_GENERAL
echo "--------------------------------------------------------------" | tee -a $LOGFILE_GENERAL
echo | tee -a $LOGFILE_GENERAL
echo "Processing starts..." | tee -a $LOGFILE_GENERAL | tee $LOGFILE_TIME
echo $TIME | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL
printf "Target:     " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
if [ $HEIGHTS == "true" ] ; then printf "heights " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; fi
if [ $MOON == "true" ] ;  then printf "moon " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; fi
echo | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo "Will work in ${RESOLUTION_MAX}x${RESOLUTION_MAX} resolution and will output" | tee -a $LOGFILE_GENERAL
printf "Resolution: " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
for r in $RESOLUTION ; do printf "%sx%s " $r $r | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; done
echo | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL
echo "--------------------------------------------------------------" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL


if [[ $DOWNLOAD == "true" ]] ; then downloadImages ; fi
if [[ $HEIGHTS == "true" ]] ; then generateMoonHeights ; fi
if [[ $MOON == "true" ]] ; then generateMoon ; fi
if [[ $MOSAIC == "true" ]] ; then generateMosaic ; fi
if [[ $CLEANUP == "true" ]] ; then cleanUp ; fi





echo | tee -a $LOGFILE_GENERAL
echo "convert.sh has finished." | tee -a $LOGFILE_GENERAL
echo | tee -a $LOGFILE_GENERAL
echo "You will find the textures in \"output\" in your requested"
echo "resolution. Copy these to \$FGDATA/Models/Astro/*"
