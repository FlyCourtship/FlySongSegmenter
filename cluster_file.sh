#!/bin/bash

#matlab: deploytool -build find_fly_song.prj
#  bash: ssh login
#  bash: cluster_file.sh full_path_to_.daq_file full_path_to_params.m  nchan

daq_path="$1"
params_path="$2"
nchan="$3"
params_name=$(basename "$params_path" ".m")
clean_params_name=$(echo "$params_name" | sed "s/[^a-zA-Z0-9 ]/_/g")

IFS=$'\n'

unset IFS
daq_name=$(basename "$daq_path" ".daq")
clean_daq_name=$(echo "$daq_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
for i in $(seq $nchan)
do
  qsub -N "FSS-$clean_daq_name-$clean_params_name-$i" -pe batch 8 -b y -j y -cwd -o "$daq_name-$params_name-$i.log" -V ./find_fly_song/distrib/run_find_fly_song.sh /usr/local/matlab-2012a "\"$daq_path\"" -p "\"$params_path\"" -c "$i" -s 1000:500000
done
