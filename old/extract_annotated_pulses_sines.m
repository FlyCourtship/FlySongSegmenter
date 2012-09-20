function [pulses,sines] = extract_annotated_pulses_sines(annotated_pulse_sine,fs)

pulse_peaks = annotated_pulse_sine.PULSE;
sine_start_stop = annotated_pulse_sine.SINE;

%For pulse
%Take ~200ms window (±100ms) around hand annontated pulse peak
window = .01 * fs;

%For sine
%Take ~200ms windows stepped through sample



