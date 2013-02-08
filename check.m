%function check(one,two)
%
%compare the output of two runs of FSS which should be identical and report the differences
%
% check('../data/20111030163601_out_sl63x1/PS_20111030163601_ch1.mat','../data/20111030163601_out_sl63x4/PS_20111030163601_ch1.mat')

function check(one,two)

one=load(one);
two=load(two);

kinds = {'Pulses' 'Sines'};

types{1} = {'Wavelet' 'AmpCull' 'IPICull' 'ModelCull' 'ModelCull2'};
fields{1} = {'wc' 'w0' 'w1' 'dog' 'fcmx' 'scmx'};

types{2} = {'TimeHarmonicMerge' 'PulsesCull' 'LengthCull'};
fields{2} = {'start' 'stop'};

for kk=1:2
  k=kinds(kk);
  for t=types{kk}
    for f=fields{kk}
      l1=length(one.(char(k)).(char(t)).(char(f)));
      l2=length(two.(char(k)).(char(t)).(char(f)));
      if(l1~=l2)
        disp([char(k) '.' char(t) '.' char(f) ' differ in length by ' num2str(abs(l1-l2))]);
      else
        idx=find(one.(char(k)).(char(t)).(char(f))~=two.(char(k)).(char(t)).(char(f)));
        if(length(idx)>0)
          disp([char(k) '.' char(t) '.' char(f) ' differ in ' num2str(length(idx)) ' places']);
          for i=1:length(idx)
            disp([num2str(one.(char(k)).(char(t)).(char(f))(idx(i))) '~=' ...
                  num2str(two.(char(k)).(char(t)).(char(f))(idx(i)))]);
          end
        end
      end
    end
  end
end
