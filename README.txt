RUNNING ON YOUR LOCAL MACHINE

use Process_Song() to analyze data already loaded into the matlab
workspace and Process_daq_Song() to analyze .daq files on disk without
first loading them.  either way, the returned results are viewed with
Plot_PulseSegmentation_Results().  all parameters are contained in params.m.


BATCHING JOBS TO THE JANELIA CLUSTER

to compile the matlab code, first login to the scheduler node.
>> qlogin -l interactive=true,matlab=1
Then start matlab
>> /usr/local/matlab-2012a/bin/matlab
Then issue the command to compile. You need to provide the full path to the code.
For example, assuming your code is in your home directory (and not wrapped in a folder)
>> deploytool -build find_fly_song.prj
Alternatively, if, for example, you put the code in the subfolder /song/code, you would issue this command.
>> deploytool -build song/code/find_fly_song.prj

Alternatively, you can do this with openNX (see our wiki: http://wiki/wiki/display/ScientificComputing/NX+Client+Setup)
instead of ssh as above. from there login to a real node using "qlogin -l interactive=true,matlab=1"
from which you can then run matlab with "/usr/local/matlab-2012a/bin/matlab &".
on the matlab command line use "deploytool -build find_fly_song.prj" to
update the executable in find_fly_song/distrib/*.

To run the compiled code
first "ssh login" from the unix command line to access the scheduler node.
then use cluster_file.sh to analyze a single .daq file, or cluster_folder.sh
for a whole folder of .daq files.  these are both shell scripts that use
qsub to call a compiled version of Process_daq_Song().  look inside cluster_f*
for syntax and details.


MORE DETAILS (dated)

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

