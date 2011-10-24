function [S,F,T,P] = compute_spectrogram(x,nwnd,nov,nfft,fs,varargin)

% [S,F,T,P] = compute_spectrogram(x,nwnd,nov,nfft,fs,varargin)
%
% x: The signal.
%
% nwnd: Size of the sliding time window. I typically use 2048
%
% nov:  Overlap between adjacent windows. I typically use 1800.
%
% nfft: Number of frequency points for the FFT. I typically use 8192.
%
% fs: Sample rate.
%
% varargin: If you don't supply this, the results are returned for
% frequencies up to fs/2. If you supply a single value, you'll get back
% results for f = 0 - fmax. If you supply two values, the first is taken as
% fmin and the second as fmax, and you get back results for frequencies in
% the range fmin - fmax.
%
% This function is basically a wrapper for 'spectrogram'. Spectrogram will
% return a matrix where each column is the FFT of a particular time window.
% The rows in each column are the coefficients for each frequency.
%
% S: The actual FFT results. You usually won't need this.
% F: The frequencies that the rows correspond to.
% T: The times each of the columns correspond to. Note that this will start
% at nwnd/2/fs because this is the center of the first bin, in seconds.
% P: The power at each frequency for each time bin. This is what you'll
% usually use.

[S,F,T,P] = spectrogram(x,window(@gausswin,nwnd),nov,nfft,fs);

% S = S.*conj(S);

switch(length(varargin))
	case 2
		fmin = varargin{1};
		fmax = varargin{2};
	case 1
		fmin = 0;
		fmax = varargin{1};
	case 0
		fmin = 0;
		fmax = fs/2;
	otherwise
		error('Maximum 2 variable arguments allowed.')
end

nStartRow 	= max(floor(fmin/fs*nfft),1);
nEndRow 	= min(ceil(fmax/fs*nfft),nfft);

S = S(nStartRow:nEndRow,:);
P = P(nStartRow:nEndRow,:);
F = F(nStartRow:nEndRow);



