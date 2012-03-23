#!/bin/bash

#matlab: deploytool -build find_fly_song.prj
#  bash: ssh login
#  bash: cluster.sh full_path_to_folder_of_.daqs full_path_to_params.m

daq_folder="$1"
params_path="$2"
params_name=$(basename "$params_path" ".m")
clean_params_name=$(echo "$params_name" | sed "s/[^a-zA-Z0-9 ]/_/g")

IFS=$'\n'

for daq_path in $(ls $daq_folder/*.daq)
do
  unset IFS
  daq_name=$(basename "$daq_path" ".daq")
  clean_daq_name=$(echo "$daq_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  qsub -N "FSS-$clean_daq_name-$clean_params_name-$i" -pe batch 8 -b y -j y -cwd -o "$daq_name-$params_name.log" -V ./find_fly_song/distrib/run_find_fly_song.sh /usr/local/matlab-2012a "\"$daq_path\"" -p "\"$params_path\"" -s 1000:1000000
done
