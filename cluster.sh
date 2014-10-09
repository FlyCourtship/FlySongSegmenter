#!/bin/bash

#cd to folder containing cluster.sh and then execute:
#./cluster.sh  full_path_to_file_or_folder_of_.daqs  full_path_to_params.m  number_of_channels

#each channel of each file is sent to it's own half node.  all files
#assumed to have the same number of channels.

#hard-coded for matlab 2013a on janelia cluster

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
do
  unset IFS
  daq_name=$(basename "$daq_file" ".daq")
  clean_daq_name=$(echo "$daq_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  if [ ! -d $daq_folder/$daq_name\_out ] ; then
    mkdir $daq_folder/$daq_name\_out
  fi
  cmd="./cluster2.sh \"$daq_file\" -p \"$params_path\" -c "'"${SGE_TASK_ID}"'
  cmd=$cmd" > $daq_folder/$daq_name""_out""/$clean_daq_name-"'${SGE_TASK_ID}'"-$clean_params_name.log"
  qsub -t 1-$nchan \
      -N FSS-$clean_daq_name-$clean_params_name \
      -pe batch 12 \
      -b y -j y -o /dev/null \
       -cwd \
       -l short=true \
       -V \
       $cmd
#      -l old=true \
#      -l short=true,h_rt=2:00:00 \
#      -l r620=true \
done
