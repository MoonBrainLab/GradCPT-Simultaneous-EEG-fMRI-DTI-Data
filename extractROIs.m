clear all; clc;

gunzip('atlas_LUT.nii.gz');
dat=niftiread('atlas_LUT.nii');
roivals=unique(dat(:)); roivals(1)=[];
mkdir('./rois');

labels=[];
for i=1:numel(roivals)
    tmp=int32(zeros(size(dat)));
    tmp(dat==roivals(i))=1;
    labels=[labels; i double(roivals(i))];
    saveniidat(['./rois/roi' num2str(i) '.nii'],tmp,'atlas_LUT.nii');
end
save('./rois/roiinfo.txt','labels','-ascii');
