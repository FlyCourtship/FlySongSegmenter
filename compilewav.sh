#!/bin/bash

#ssh login to cluster
#qlogin -l interactive=true
#cd to VisMap/
#./compile.sh

#hard-coded for matlab 2013a on janelia cluster

mkdir -p FSSwav

#  -R -singleCompThread \
/usr/local/matlab-2013a/bin/mcc -o FSSwav \
  -W main:FSSwav \
  -T link:exe \
  -d FSSwav \
  -w enable:specified_file_mismatch \
  -w enable:repeated_file \
  -w enable:switch_ignored \
  -w enable:missing_lib_sentinel \
  -w enable:demo_license \
  -v FlySongSegmenterWAV.m \
  -a alignment \
  -a centroid_tracking \
  -a utilities 

chmod g+x ./FSSwav/run_FSSwav.sh
chmod g+x ./FSSwav/FSSwav
