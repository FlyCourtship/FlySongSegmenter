RUNNING ON YOUR LOCAL MACHINE

start matlab and use Process_Song() to analyze data already loaded into
the matlab workspace or Process_daq_Song() to analyze .daq files on disk
without first loading them.  either way, the returned results are viewed with
Plot_PulseSegmentation_Results().  all parameters are contained in params.m.


BATCHING JOBS TO THE JANELIA CLUSTER

(1) compile the matlab code

first login to the cluster's scheduler node, either directly with openNX
(see our wiki: http://wiki/wiki/display/ScientificComputing/NX+Client+Setup)
or indirectly via SSH ("ssh login" on a mac using terminal.app or on a PC
using putty.exe).  once there, login to a real compute node:

$ qlogin -l interactive=true,matlab=1

Then start matlab

$ /usr/local/matlab-2012a/bin/matlab

Then issue the command to compile. You need to provide the full path to the
code.  For example, assuming your code is in your home directory (and not
wrapped in a folder)

>> deploytool -build find_fly_song.prj

Alternatively, if, for example, you put the code in the subfolder /song/code,
you would issue this command.

>> deploytool -build song/code/find_fly_song.prj

If you don't want to launch matlab, you can compile from the unix command
line using

$ mcc -vm -I chronux -I order find_fly_song.m

note:  doing it this way will put the executables in FSS/ not
FSS/find_fly_song/.  if you have problems with disk space try
deleting/moving/renaming find_fly_song.prj, which deploytool uses, but
somehow seemingly screws up mcc.

(2) get a scratch folder

jobs on the janelia cluster see your home directory.  matlab
normally writes temporary files to ~/.mcrCache.  if you run
multiple jobs at once these files get overwritten, and matlab
can't open a pool of workers.  so contact the help desk and ask
them to create a scratch folder for your account on the cluster.
this will not be on your disk share but rather on a local disk on
each slot of the cluster.  if /scratch is present, the scripts
will automatically tell matlab to put the temp files there, and
they will hence not be overwritten.


(3) run the compiled code

first login to the cluster's scheduler node as before, or exit out of
the real compute node if you had qlogin'ed to compile.  then "cd" to the
directory cluster.sh lives in.  this will depend on where you put it in
your home directory.

$ cd /home/username/bin

then batch jobs to the cluser.

$ ./cluster.sh  full_path_to_folder_of_.daqs  full_path_to_params.m  number_of_channels

cluster.sh is a shell script that use qsub to call a compiled version of
Process_daq_Song().


LIGHTSPEED TOOLBOX

depending on your machine architecture, you might see dramatic speed
improvements with:

http://research.microsoft.com/en-us/um/people/minka/software/lightspeed/



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

There is much more information about how the segmenter works buried in the code -- please read all of the comments.

