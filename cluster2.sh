#!/bin/bash

export MCR_CACHE_VERBOSE=1

hostname

if [ -d /scratch/$USER ]
  then
    export MCR_CACHE_ROOT=/scratch/$USER/mcr_cache_root.$JOB_ID
  else
    export MCR_CACHE_ROOT=~/mcr_cache_root.$JOB_ID
fi

if [ -d MCR_CACHE_ROOT ]
  then
    echo Deleting pre-existing MCR_CACHE_ROOT
    rm -rf $MCR_CACHE_ROOT
fi

fly_song_segmenter_unix/distrib/run_fly_song_segmenter.sh /usr/local/matlab-2012a $1 $2 $3 $4 $5

rm -rf $MCR_CACHE_ROOT
