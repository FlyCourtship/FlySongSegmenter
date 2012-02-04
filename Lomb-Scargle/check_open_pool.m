function [poolavail,isOpen] = check_open_pool

%[poolavail,isOpen] = check_open_pool

poolavail = exist('matlabpool','file');
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
        matlabpool(getenv('NUMBER_OF_PROCESSORS'))
        isOpen = -1;%now know pool was opened in this script (no negative pools from matlabpool('size'))
    end
end
