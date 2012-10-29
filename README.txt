FLY SONG SEGMENTER

A tool for analyzing audio recordings of the courtship song of the fruit
fly Drosophila melanogaster and related species.  Given the raw time series,
the program outputs time stamps demarcating the beginning and end of both
sine and pulse song.


COPYRIGHT

The portions of this software created by the Janelia Farm Research
Campus of the Howard Hughes Medical Institute are subject to the
license at http://license.janelia.org/license.


SYSTEM REQUIREMENTS

Matlab and the following toolboxes:  Signal, Statistics, Wavelet, and
not-necessary but highly-recommended Distributed Computing.  Alternatively,
one can bypass Matlab and run the provided executables on the command
line using the Matlab Compiler Runtime library.


RUNNING ON YOUR LOCAL MACHINE

Start Matlab and use FlySongSegmenter() to analyze data already loaded
into the Matlab workspace or FlySongSegmenterDAQ() to analyze .daq files
on disk without first loading them.  The former returns the results to the
workspace, while the latter saves them to disk in a .mat file.  Either way,
the results can be viewed with PlotSegmentation().  All parameters are
contained in FetchParams.m.

FlySongSegmenterDAQ has been packaged into an executable called
fly_song_segmenter.  If you do not have Matlab or prefer to run a stand-alone
executable instead (e.g. on a cluster), first download and install the MCR:

http://www.mathworks.com/products/compiler/mcr/

From the command line, cd into fly_song_segmenter_<platform>/distrib,
where <platform> is either pc, mac, or unix, and execute

./fly_song_segmenter <full-path-to-matlab-binary> -p <full-path-to-params-file> -c <channel-number>


MORE DETAILS

1mintestsong.mat contains three test songs (easy, medium, difficult) and
one sample of noise.  Load it into your workspace:

>> load 1mintestsong

You can segment song with or without the noise file. If you don't provide
a noise file, then noise is estimated from the data.  To segment the song:

>> [data,Sines,Pulses,Params] = FlySongSegmenter(easy,[],[])

To view the results:

>> PlotSegmentation(data,Sines,Pulses)

Sines is a structure that has all of the information on the sine song
and Pulses is a structure that has all of the information on the pulses.
You can then analyze these extracted elements (individual pulses and
sinusoids) however you like.

Specifically, Sines.TimeHarmonicMerge contains sine song which has been
merged over continguous time segments and across harmonics;  Sines.PulsesCull
is the subset of Sines.TimeHarmonicMerge which does not occur within pulse
song;  and Sines.LengthCull is the subset of Sines.PulsesCull which exceeds a
specified minimum length.

Similarly, Pulses.AmpCull is the subset of Pulses.Wavelet which exceeds a
specified amplitude, and Pulses.IPICull is the subset of Pulses.AmpCull
which is within specified bounds on IPI and fundamental frequency.
Pulses.ModelCull and Pulses.ModelCull2 are subsets of Pulses.AmpCull and
Pulses.IPICull, respectively, which fit a specified model.

To optimize segmentation for your recordings, you might have to adjust
several parameters by modifiying params.m.  We suggest you do this on
a small (~1 min) but representative section of your data.  The utility
FlySongSegmenterByHand() provides a way to manually ground truth data, and
CompareManual2AutoSegmentation() calculates how well manual and automatic
segmentation coincide.

There is much more information about how FlySongSegmenter works buried in
the code of its subfunctions -- please read all of the comments.


LIGHTSPEED TOOLBOX

Depending on your machine architecture, you might see dramatic speed
improvements with:

http://research.microsoft.com/en-us/um/people/minka/software/lightspeed/


BATCHING JOBS TO THE JANELIA CLUSTER

(1) Compile the Matlab code

First login to the cluster's scheduler node, either directly with openNX
(see our wiki: http://wiki/wiki/display/ScientificComputing/NX+Client+Setup)
or indirectly via SSH ("ssh login" on a Mac using terminal.app or on a PC
using putty.exe).  Once there, login to a real compute node:

$ qlogin -l interactive=true,matlab=1

Then start Matlab

$ /usr/local/matlab-2012a/bin/matlab

Then issue the command to compile. You need to provide the full path to
the code.  For example, assuming your code is in your home directory (and
not wrapped in a folder)

>> deploytool -build find_fly_song.prj

Alternatively, if, for example, you put the code in the subfolder /song/code,
you would issue this command.

>> deploytool -build song/code/find_fly_song.prj

If you don't want to launch Matlab, you can compile from the Unix command
line using

$ mcc -vm -I chronux -I order find_fly_song.m

Note:  doing it this way will put the executables in FSS/ not
FSS/find_fly_song/.  If you have problems with disk space try
deleting/moving/renaming find_fly_song.prj, which deploytool uses, but
somehow seemingly screws up mcc.

(2) Get a scratch folder

Jobs on the Janelia cluster see your home directory.  Matlab normally writes
temporary files to ~/.mcrCache.  If you run multiple jobs at once these files
get overwritten, and Matlab can't open a pool of workers.  So contact the help
desk and ask them to create a scratch folder for your account on the cluster.
This will not be on your disk share but rather on a local disk on each slot
of the cluster.  If /scratch is present, the scripts will automatically tell
matlab to put the temp files there, and they will hence not be overwritten.


(3) Run the compiled code

First login to the cluster's scheduler node as before, or exit out of
the real compute node if you had qlogin'ed to compile.  Then "cd" to the
directory cluster.sh lives in.  This will depend on where you put it in
your home directory.

$ cd /home/username/bin

Then batch jobs to the cluster.

$ ./cluster.sh  full_path_to_file_or_folder_of_.daqs  full_path_to_params.m  number_of_channels

cluster.sh is a shell script that uses qsub() to call a compiled version of
FlySongSegmenterDAQ().
