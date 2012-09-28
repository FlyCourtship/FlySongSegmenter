#!/bin/bash

#cd to folder containing cluster.sh and then execute:
#./cluster.sh  full_path_to_file_or_folder_of_.daqs  full_path_to_params.m  number_of_channels

#each channel of each file is sent to it's own half node.  all files
#assumed to have the same number of channels.

daq_file_or_folder="$1"
params_path="$2"
nchan="$3"
params_name=$(basename "$params_path" ".m")
clean_params_name=$(echo "$params_name" | sed "s/[^a-zA-Z0-9 ]/_/g")

IFS=$'\n'

if [ -d $daq_file_or_folder ] ; then
  daq_files=$(ls -1 $daq_file_or_folder/*.daq)
  daq_folder=$daq_file_or_folder
else
  daq_files=$daq_file_or_folder
  daq_folder=$(dirname $daq_file_or_folder)
fi
for daq_file in $daq_files
#for daq_file in $(ls $daq_folder/*.daq)
do
  unset IFS
  daq_name=$(basename "$daq_file" ".daq")
  clean_daq_name=$(echo "$daq_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  if [ ! -d $daq_folder/$daq_name\_out ] ; then
    mkdir $daq_folder/$daq_name\_out
  fi
  for i in $(seq $nchan)
  do
    #qsub -N FSS-$clean_daq_name-$i-$clean_params_name -l short=true -pe batch 4 -b y -j y -cwd -o $daq_folder/$daq_name\_out/$clean_daq_name-$i-$clean_params_name.log -V ./cluster2.sh "\"$daq_file\"" -p "\"$params_path\"" -c "$i"
    qsub -N FSS-$clean_daq_name-$i-$clean_params_name -b y -j y -cwd -o $daq_folder/$daq_name\_out/$clean_daq_name-$i-$clean_params_name.log -V ./cluster2.sh "\"$daq_file\"" -p "\"$params_path\"" -c "$i"
    #sleep 1
  done
done
