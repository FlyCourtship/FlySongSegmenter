function array_hygro(obj,event)

global ai button_save text_filedir filename text_hygro

transmission_start=[0 1 1 0 1 1 0 0;
                    1 1 0 0 0 1 1 0];
measure_temp=[1 0 1 0 1 0 1 0 1 0 1 0 0 1 0 1 0;
              0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1];
measure_RH  =[1 0 1 0 1 0 1 0 1 0 0 1 0 0 1 0 0 1 0;
              0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 1 1 1];

%keyboard
err=1;
while(err)
  hygro_write(transmission_start);
  hygro_write(measure_temp);
  err=hygro_wait_ack();
end
T=hygro_read();
T=-40.1+0.01.*T;  % 5V, 14-bit
%disp(['T=' num2str(T)]);

err=1;
while(err)
  hygro_write(transmission_start);
  hygro_write(measure_RH);
  err=hygro_wait_ack();
end
RH=hygro_read();
tmp=-2.0468+0.0367.*RH-1.5955e-6.*RH.^2;
RH=(T-25).*(0.01+0.00008.*RH)+tmp;
%disp(['RH=' num2str(RH)]);

for(i=1:length(T))
  set(text_hygro(i),'string',[num2str(T(i),'%2.1f') 'C,' num2str(RH(i),2) '%']);
end

if(get(button_save,'value'))
  fid=fopen([get(text_filedir,'string') '\' filename '.hyg'],'a');
  fprintf(fid,'%f ',etime(clock,get(ai,'InitialTriggerTime')));
  fprintf(fid,'%f ',T);
  fprintf(fid,'%f ',RH);
  fprintf(fid,'\n');
  fclose(fid);
end



function hygro_write(data)

global dio hygro_clockperiod

for(i=1:size(data,2))
  putvalue([dio.HygroClk dio.HygroOut],[data(1,i) ~data(2,i)]);
  pause(hygro_clockperiod);
end



function err=hygro_wait_ack()

global dio hygro_clockperiod  hygro_timeout  hygro_datain

tic;
while((sum(getvalue(dio.HygroIn))>0) && (toc<hygro_timeout))  end
if(sum(getvalue(dio.HygroIn))>0)
  disp('hygro timed out 1');
  putvalue(dio.HygroOut,~1);
  for(i=1:10)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  err=1;
  return;
end
putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
putvalue(dio.HygroClk,0);  pause(0.1);
tic;
while((sum(getvalue(dio.HygroIn))>0) && (toc<hygro_timeout))  end
if(sum(getvalue(dio.HygroIn)>0))
  disp('hygro timed out 2');
  putvalue(dio.HygroOut,~1);
  for(i=1:10)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  err=1;
  return;
end
err=0;



function ret_val=hygro_read()

global dio hygro_clockperiod  hygro_datain

idx=4:3+length(hygro_datain);

tmp=zeros(length(hygro_datain),2);
for(i=1:2)
  for(j=7:-1:0)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    tmp(:,i)=tmp(:,i)+(2^j).*getvalue(dio.HygroIn)';
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  if(i==1)
    putvalue(dio.HygroOut,~0);  pause(hygro_clockperiod);
  end
  putvalue(dio.HygroClk,1);   pause(hygro_clockperiod);
  putvalue(dio.HygroClk,0);   pause(hygro_clockperiod);
  putvalue(dio.HygroOut,~1);  pause(hygro_clockperiod);
end

ret_val=256*tmp(:,1)+tmp(:,2);
ret_val=ret_val';
