function check_close_pool(poolavail,isOpen)

%if(isdeployed)  return;  end

if isOpen == -1%if pool opened in this script, then close
  if poolavail~=0
    try
      matlabpool close
    catch
      disp('WARNING:  problem closing matlabpool.  will save results and finish anyway');
    end
  end
end
