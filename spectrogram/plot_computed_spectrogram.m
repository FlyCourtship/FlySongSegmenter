function h = plot_computed_spectrogram(S,F,T,P)
% h = plot_computed_spectrogram(S,F,T,P)
%
% Plots the results returned from compute_spectrogram. Returns a handle to
% the resulting graph.
%

cla;
h = imagesc([T(1) T(end)],[F(1) F(end)], P); axis xy;