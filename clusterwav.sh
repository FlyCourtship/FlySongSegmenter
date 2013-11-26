#!/bin/bash

#cd to folder containing cluster.sh and then execute:
#./cluster.sh  full_path_to_avi_or_folder_of_avis start_frame end_frame
#leave start_frame and end_frame blank if process whole movie

#each movie in the folder is sent to it's own node.

#hard-coded for matlab 2013a on janelia cluster

wav_or_folder="$1"
params_file="$2"

#TO DO: add line to remove trailing / from folder if exists

IFS=$'\n'

if [ -d $wav_or_folder ] ; then
  wav_files=$(ls -1 $wav_or_folder/*.wav)
  wav_folder=$wav_or_folder
else
  wav_files=$wav_or_folder
  wav_folder=$(dirname $wav_or_folder)
fi
for wav_file in $wav_files
do
  unset IFS
  avi_name=$(basename "$wav_file" ".wav")
  clean_avi_name=$(echo "$wav_name" | sed "s/[^a-zA-Z0-9 ]/_/g")
  cmd="./clusterwav2.sh \"$wav_file\" -s \"$params_file\" "

  cmd=$cmd" > $wav_folder/$clean_wav_name.log"
  qsub -N VM-$clean_wav_name \
      -pe batch 1 \
      -b y -j y -o /dev/null \
       -cwd \
       -V \
       $cmd
#      -l short=true,h_rt=2:00:00 \
#      -l r620=true \
done
