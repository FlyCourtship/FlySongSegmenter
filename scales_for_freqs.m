function sc = scales_for_freqs(freqs, dt,wav)
% SC = SCALES_FOR_FREQS(FREQS, DT, WAV)
% 
% Computes the scales for the frequencies in the vector FREQS for
% the wavelet WAV e.g. 'morl'. DT is the sample period, i.e. 1/sample rate.
%

K = scal2frq(1,wav,dt);

sc = K./freqs;