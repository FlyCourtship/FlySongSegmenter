function check_close_pool(poolavail,isOpen)

if isOpen == -1%if pool opened in this script, then close
    if poolavail~=0
        matlabpool close force local
    end
end
