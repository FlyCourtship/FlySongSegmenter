To Run FLYSONG_SEGMENTER:

load 1mintestsong.mat to your workspace
There are three test songs (easy, medium, difficult) and one sample of noise

You can run segmented with or without the noise file. If you don't provide a noise file, then noise is estimated from the data.
To run call Process_Song
[ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo,cmhSong,cmhNoise,cmo,cPnts] = Process_Song(xsong,xempty)

e.g.
[ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo,cmhSong,cmhNoise,cmo,cPnts] = Process_Song(easy)
or
[ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo,cmhSong,cmhNoise,cmo,cPnts] = Process_Song(easy,noise)

To view the results:

Plot_PulseSegmentation_Results(ssf,winnowed_sine,pcndInfo,pulseInfo,pulseInfo2,pps)

pulseinfo2 is a structure that has all of the information on the pulses and winnowed_sine is a structure that has all of the information on the sine songs.  You can then analyze these extracted elements (individual pulses and sinusoids) however you like.

To optimize segmentation for your recordings, you will have to adjust several parameters, many of which are in the m file Process_Song, but some of which are still in the functions called by this m file.  We suggest you do this on a small (~1 min) but representative section of your data.

There is much more information about how the segmented works buried in the code -- please read all of the comments.

