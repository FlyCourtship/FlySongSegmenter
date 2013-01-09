FLY SONG SEGMENTER

A tool for analyzing audio recordings of the courtship song of the fruit
fly Drosophila melanogaster and related species.  Given the raw time series,
the program outputs time stamps demarcating the beginning and end of both
sine and pulse song.


COPYRIGHT

Copyright (c) 2013, Princeton University and Howard Hughes Medical
Institute, All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of Princeton University and/or the Howard Hughes
   Medical Institute nor the names of its contributors (Mala Murthy
   and/or David Stern) may be used to endorse or promote products derived
   from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
ANY IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; REASONABLE ROYALTIES; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


SYSTEM REQUIREMENTS

Matlab and the following toolboxes:  Signal, Statistics, Wavelet, and
not-necessary but highly-recommended Distributed Computing.


RUNNING ON YOUR LOCAL MACHINE

Start Matlab and use FlySongSegmenter() to analyze data already loaded
into the Matlab workspace or FlySongSegmenterDAQ() to analyze .daq files
on disk without first loading them.  The former returns the results to the
workspace, while the latter saves them to disk in a .mat file.  Either way,
the results can be viewed with PlotSegmentation().  All parameters are
contained in FetchParams.m.


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
