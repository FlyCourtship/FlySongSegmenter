#!/bin/bash

#cd to folder containing cluster.sh and then execute:
#./cluster.sh  full_path_to_file_or_folder_of_.daqs/.wavs  full_path_to_params.m  number_of_channels

#each channel of each file is sent to it's own node.  all files
#assumed to have the same number of channels.

#hard-coded for matlab 2013a on janelia cluster

data_file_or_folder="$1"
params_path="$2"
nchan="$3"
params_name=$(basename "$params_path" ".m")
clean_params_name=$(echo "$params_name" | sed "s/[^a-zA-Z0-9 ]/_/g")

IFS=$'\n'

if [ -d $data_file_or_folder ] ; then
  data_files=$(ls -1 $data_file_or_folder/*.daq $data_file_or_folder/*.wav)
  data_folder=$data_file_or_folder
else
  data_files=$data_file_or_folder
  data_folder=$(dirname $data_file_or_folder)
fi
for data_file in $data_files ; do
  unset IFS
  data_name=$(basename $(basename "$data_file" ".daq") ".wav")
  clean_data_name=$(echo "$data_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  if [ ! -d $data_folder/$data_name\_out ] ; then
    mkdir $data_folder/$data_name\_out
  fi
  cmd="./cluster2.sh \"$data_file\" -p \"$params_path\" -c "'"${LSB_JOBINDEX}"'
  cmd=$cmd" > $data_folder/$data_name""_out""/$clean_data_name-"'${LSB_JOBINDEX}'"-$clean_params_name.log"
  bsub -J FSS-$clean_data_name-$clean_params_name[1-$nchan] \
       -n 12 -R"affinity[core(1)]" \
       -o /dev/null \
       -W 60 \
       $cmd
done
