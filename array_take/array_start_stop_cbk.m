function array_start_stop_cbk(obj,event)

global Fs range_settings start_stop
global ai running button_exit button_start_stop popupmenu_hygro popupmenu_nchan edit_samplerate popupmenu_range popupmenu_daq
global button_save text_filedir button_wav edit_filesize
global dio filename t hygro_period

if(running && (start_stop==-1 || ~getvalue(dio.StartStop)))
  running=0;
  stop(ai);
  if(get(button_save,'value') && get(button_wav,'value'))
    file=[get(text_filedir,'string') '\' filename];
    dinfo=daqread([file '.daq'],'info');
    fsize=get(edit_filesize,'string');
    if(~isempty(fsize))
      fsize=round(str2num(fsize)*60*Fs);
    else
      fsize=dinfo.ObjInfo.SamplesAcquired;
    end
    range=range_settings(get(popupmenu_range,'value'));
    for(i=1:length(dinfo.ObjInfo.Channel))
      for(j=1:fsize:dinfo.ObjInfo.SamplesAcquired)
        d=daqread([file '.daq'],'Channels',i,...
            'Samples',[j min(j+fsize-1,dinfo.ObjInfo.SamplesAcquired)]);
        d=d./range;
        wavwrite(d,Fs,16,[file '.' num2str(i) '.' num2str(1+round((j-1)/fsize)) '.wav']);
      end
    end
  end
  set(button_exit,'enable','on');
  if(start_stop==-1)  set(button_start_stop,'string','start','backgroundColor',[0 1 0]);  end
  set(popupmenu_daq,'enable','on');
  set(popupmenu_nchan,'enable','on');
  set(edit_samplerate,'enable','on');
  set(popupmenu_range,'enable','on');
  set(popupmenu_hygro,'enable','on');
  if(get(button_save,'value'))
    set(button_wav,'enable','on');
    if(get(button_wav,'value'))
      set(edit_filesize,'enable','on');
    end
  end
  set(text_filedir,'enable','on');
  set(button_save,'enable','on');
  stop(t);
  delete(t);
  
elseif(~running && (start_stop==-1 || getvalue(dio.StartStop)))
  if(get(button_save,'value'))
    filename=sprintf('%02d',round(clock'));
    set(ai,'LogFileName',[get(text_filedir,'string') '\' filename '.daq']);
    set(ai,'LoggingMode','Disk&Memory');
  else
    filename=[];
    set(ai,'LoggingMode','Memory');
  end
  running=1;
  start(ai);
  trigger(ai);
  set(button_exit,'enable','off');
  if(start_stop==-1)  set(button_start_stop,'string','stop','backgroundColor',[1 0 0]);  end
  set(popupmenu_daq,'enable','off');
  set(popupmenu_nchan,'enable','off');
  set(edit_samplerate,'enable','off');
  set(popupmenu_range,'enable','off');
  set(popupmenu_hygro,'enable','off');
  set(button_wav,'enable','off');
  set(edit_filesize,'enable','off');
  set(text_filedir,'enable','off');
  set(button_save,'enable','off');
  
  t=timer;
  set(t,'Name','hygrometer');
  set(t,'Period',hygro_period);
  set(t,'ExecutionMode','fixedRate');
  set(t,'TimerFcn',@array_hygro);
  start(t);
end
