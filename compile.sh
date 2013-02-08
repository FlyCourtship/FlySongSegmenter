#ssh login to cluster, cd to FlySongSegmenter/, ./compile.sh

#hard-coded for matlab 2012b on janelia cluster

mkdir -p fly_song_segmenter

#  -R -singleCompThread \
/usr/local/matlab-2012b/bin/mcc -o fly_song_segmenter \
  -W main:fly_song_segmenter \
  -T link:exe \
  -d fly_song_segmenter \
  -w enable:specified_file_mismatch \
  -w enable:repeated_file \
  -w enable:switch_ignored \
  -w enable:missing_lib_sentinel \
  -w enable:demo_license \
  -v fly_song_segmenter.m \
  -a chronux \
  -a order \
  -a padcat2 

