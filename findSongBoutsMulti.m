function findSongBoutsMulti(folder)





W = who('-file',path_file);
varstruc =struct;
load(path_file);
for ii = 1:numel(W)
    varstruc.(W{ii}) = eval(W{ii});
end
varstruc.bouts = bouts;

varstruc.bout.variables.date = date;
varstruc.bouts.variables.time = clock;
save(path_file,'-struct','varstruc','-mat')%save all variables in original file