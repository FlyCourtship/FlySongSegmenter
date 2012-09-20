function [poolavail,isOpen] = check_open_pool
%[poolavail,isOpen] = check_open_pool

if(isdeployed)
%  num_procs=4;
  poolavail=0;
  isOpen=0;
  return;
else
  num_procs=getenv('NUMBER_OF_PROCESSORS');
end

poolavail = exist('matlabpool','file');
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
      try
        matlabpool(num_procs)  % crashes the cluster if you don't have local scratch space
        isOpen = -1;%now know pool was opened in this script (no negative pools from matlabpool('size'))
      catch
        disp('WARNING: could not open matlab pool.  proceeding with a single thread.');
      end
    end
else
    isOpen = 0;
end
