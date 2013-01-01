function culled_pulseInfo = CullPulses(pulseInfo,Lik,range)
%culled_pulseInfo = CullPulses(pulseInfo,Lik,[0 100])
if isempty(Lik)
    culled_pulseInfo = [];
    return
end
culled_pulses.dog = pulseInfo.dog(Lik>range(1) & Lik<range(2));
culled_pulses.fcmx = pulseInfo.fcmx(Lik>range(1) & Lik<range(2));
culled_pulses.wc= pulseInfo.wc(Lik>range(1) & Lik<range(2));
culled_pulses.w0= pulseInfo.w0(Lik>range(1) & Lik<range(2));
culled_pulses.w1= pulseInfo.w1(Lik>range(1) & Lik<range(2));
culled_pulses.x = pulseInfo.x(Lik>range(1) & Lik<range(2));
% culled_pulses.mxv = pulseInfo.mxv(Lik>range(1) &  Lik<range(2));
% culled_pulses.aven = pulseInfo.aven(Lik>range(1) & Lik<range(2));
culled_pulses.scmx = pulseInfo.scmx(Lik>range(1) & Lik<range(2));

culled_pulseInfo = culled_pulses;
