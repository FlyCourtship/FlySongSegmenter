function array_init

global Fs range_settings count start_stop in_port out_port
global ai running popupmenu_hygro popupmenu_nchan edit_samplerate popupmenu_range popupmenu_daq
global buttons_chan
global dio hygro_period hygro_datain hygro_dataout hygro_clock

if(~isempty(ai))  delete(ai);  end
if(~isempty(buttons_chan))  delete(buttons_chan);  end

Fs=str2num(get(edit_samplerate,'string'));
nchan=get(popupmenu_nchan,'value');
hygro_period=60*2^(get(popupmenu_hygro,'value')-2);
range=range_settings(get(popupmenu_range,'value'));
daq=daqhwinfo('nidaq','InstalledBoardIds');
daq=char(daq(get(popupmenu_daq,'value')));

ai = analoginput('nidaq',daq);
set(ai,'InputType','NonReferencedSingleEnded');
for(i=0:nchan-1)
  tmp=addchannel(ai,i);
  set(tmp,'InputRange',[-range range]);
end
set(ai,'SampleRate',Fs);
set(ai,'SamplesPerTrigger',inf)
set(ai,'SamplesAcquiredFcn',{'array_plot_data'})
set(ai,'SamplesAcquiredFcnCount',count)
set(ai,'TriggerType','Manual')

dio = digitalio('nidaq',daq);
if(start_stop>-1)
  addline(dio,start_stop,in_port,'in','StartStop');
end
addline(dio,hygro_clock,out_port,'out','HygroClk');
addline(dio,hygro_dataout,out_port,'out','HygroOut');
addline(dio,hygro_datain,in_port,'in','HygroIn');
running=0;
if(start_stop>-1)
  set(dio,'TimerFcn',{'array_start_stop_cbk'});
end
start(dio);

buttons_chan=uibuttongroup('unit','pixels','position',[0 0 1 1],...
   'SelectionChangeFcn',@selcbk);
tmp=get(gcf,'position');  tmp2=get(gcf,'color');
for(i=0:nchan-1)
  uicontrol('parent',buttons_chan,'style','radiobutton','string',i+1,...
     'backgroundColor',tmp2,'position',[0.05*tmp(3)+0.9*(i+1)*tmp(3)/(nchan+1) 2 40 20]);
end


function selcbk(source,eventdata)

global chan

chan=str2num(get(eventdata.NewValue,'string'));
