#!/bin/bash

#cd to folder containing cluster.sh and then execute:
#./cluster.sh  full_path_to_folder_of_.daqs  full_path_to_params.m  number_of_channels

#each channel of each file is sent to it's own whole node.  all files
#assumed to have the same number of channels.

daq_folder="$1"
params_path="$2"
nchan="$3"
params_name=$(basename "$params_path" ".m")
clean_params_name=$(echo "$params_name" | sed "s/[^a-zA-Z0-9 ]/_/g")

IFS=$'\n'

for daq_file in $(ls $daq_folder/*.daq)
do
  unset IFS
  daq_name=$(basename "$daq_file" ".daq")
  clean_daq_name=$(echo "$daq_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  for i in $(seq $nchan)
  do
    qsub -N "FSS-$clean_daq_name-$i-$clean_params_name" -pe batch 8 -b y -j y -cwd -o "$clean_daq_name-$i-$clean_params_name.log" -V ./find_fly_song/distrib/run_find_fly_song.sh /usr/local/matlab-2012a "\"$daq_file\"" -p "\"$params_path\"" -c "$i"
  done
done
