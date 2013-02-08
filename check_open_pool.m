function [poolavail,isOpen] = check_open_pool
%[poolavail,isOpen] = check_open_pool

%num_procs=feature('numCores');
num_procs=8;

poolavail = exist('matlabpool','file');
if poolavail~=0
  %check if pools open (as might occur, for eg if called from Process_multi_daq_Song
  isOpen = matlabpool('size') > 0;
  if isOpen == 0%if not open, then open
    try
      matlabpool(num_procs)  % crashes the cluster if you don't have local scratch space
      isOpen = -1;%now know pool was opened in this script (no negative pools from matlabpool('size'))
    catch
      disp('WARNING: Could not open matlab pool. Proceeding with a single thread.');
    end
  end
else
  isOpen = 0;
end
