To generate a pulse model and calculate the log likelihood ratio that each pulse comes from this family. This is useful for identifying false positives. You can then cull the false positives (e.g. LLR < 2)

For example:

[PM,LP] = fit_pulseharm_model(pulseInfo2.x);
Plot_Lik(ssf,pulseInfo2,winnowed_sine,'no',LP.LLR_best)
culled_pulseInfo = cull_pulses(pulseInfo,LP.LLR_best,[2 200])

