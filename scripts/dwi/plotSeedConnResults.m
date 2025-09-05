close all; clear all; clc;

mat=[];
for i=1:107
    dat=load(['seed2all_roi' num2str(i) '.txt']);
    %% How many voxels are connected to target ROIs (ratio)

    if size(dat,1) ~= 1
        dat=sum(dat>0)/size(dat,1);
        mat=[mat; dat];
    else
        mat=[mat; dat];
    end
end
figure; imagesc(mat,[0 1]); axis('square'); colorbar;
set(gcf,'pos',[100 100 1200 900]);
set(gca,'xtick',0,'xticklabel','','ytick',0,'yticklabel','');
saveas(1,'./ConnectivityMatrix.jpg'); close all;

conn_bin = mat > 10;
density = sum(conn_bin(:)) / numel(conn_bin);
