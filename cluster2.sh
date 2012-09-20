#!/bin/bash

export MCR_CACHE_VERBOSE=1

hostname

if [ -d /scratch/$USER ]
  then
    export MCR_CACHE_ROOT=/scratch/$USER/mcr_cache_root.$JOB_ID
    #export MCR_CACHE_ROOT=/scratch/arthurb/mcr_cache_root.$JOB_ID
  else
    export MCR_CACHE_ROOT=~/mcr_cache_root.$JOB_ID
fi

fly_song_segmenter_unix/distrib/run_fly_song_segmenter_unix.sh /usr/local/matlab-2012a $1 $2 $3 $4 $5

if [ -d /scratch/$USER ]
  then
    rm -rf $MCR_CACHE_ROOT
fi
