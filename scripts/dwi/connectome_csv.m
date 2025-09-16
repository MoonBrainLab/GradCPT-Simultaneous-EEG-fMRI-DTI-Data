% ==============================================================
% Build Connectome CSVs for All Subjects
%
% Description:
%   This script constructs connectome matrices (streamline count and mean
%   length) for all subjects, based on diffusion tractography results.
%   The script loops through subjects, loads seed-to-target connectivity
%   files, computes pairwise connectomes, symmetrizes them, and saves
%   the results as CSV files.
%
% Requirements:
%   - MATLAB R2020b or later
%   - Subject-specific seed connectivity text files:
%       seed2all_roiX.txt (streamline counts)
%       seed2all_length_roiX.txt (streamline lengths)
%   - Atlas file: atlas_LUT.nii.gz
%
% Inputs:
%   Edit the 'Parameters' section below to set paths and subjects.
%
% Outputs:
%   - connectome_probabilistic_streamline_count.csv
%   - connectome_mean_length.csv
%
% Author: So-Hyun Han and Yeji Lee
% Last updated: 2025-09-16
% ==============================================================

%% Parameters (edit as needed)
subjectList = setdiff(1:29, [3,7,11,12]);   % Subjects to include
nROIs       = 108;                          % Number of ROIs
baseDir     = '/path/to/DATA_processed/';   % Input base directory
resultDir   = '/path/to/DWI_processed/';    % Output base directory

%% Main loop
for subj = subjectList
    subjID  = sprintf('subject%02d', subj);
    subjDir = fullfile(baseDir, subjID);
    seedDir = fullfile(subjDir, 'connectome', 'SeedConnResults');

    fprintf('\n--- Processing %s ---\n', subjID);

    % Preallocate connectomes
    connectome_count  = zeros(nROIs, nROIs);
    connectome_length = zeros(nROIs, nROIs);

    % Check atlas (optional)
    atlasPath = fullfile(subjDir, 'processed', 'atlas_LUT.nii.gz');
    if ~isfile(atlasPath)
        warning('Atlas file missing for %s. Skipping.', subjID);
        continue;
    end
    atlas = niftiread(atlasPath); %#ok<NASGU>

    % Loop over seeds
    for seed = 1:nROIs
        % --- streamline counts
        fnameCount = fullfile(seedDir, sprintf('seed2all_roi%d.txt', seed));
        if ~isfile(fnameCount)
            warning('Missing file: %s', fnameCount);
            continue;
        end
        dat = load(fnameCount); % [voxels × targets]
        dat = dat(:, 1:min(nROIs, size(dat,2)));  
        counts = sum(dat > 0) / size(dat,1);
        connectome_count(seed, 1:numel(counts)) = counts;

        % --- streamline lengths
        fnameLen = fullfile(seedDir, sprintf('seed2all_length_roi%d.txt', seed));
        if ~isfile(fnameLen)
            warning('Missing file: %s', fnameLen);
            continue;
        end
        dat_len = load(fnameLen);
        dat_len = dat_len(:, 1:min(nROIs, size(dat_len,2)));
        mean_lengths = mean(dat_len, 1, 'omitnan');
        connectome_length(seed, 1:numel(mean_lengths)) = mean_lengths;
    end

    % Symmetrize
    connectome_count  = (connectome_count + connectome_count') / 2;
    connectome_length = (connectome_length + connectome_length') / 2;

    % Save results
    outDir = fullfile(resultDir, [subjID '_processed'], 'connectomes');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writematrix(connectome_count,  fullfile(outDir, 'connectome_probabilistic_streamline_count.csv'));
    writematrix(connectome_length, fullfile(outDir, 'connectome_mean_length.csv'));

    fprintf('✅ Finished %s\n', subjID);
end
