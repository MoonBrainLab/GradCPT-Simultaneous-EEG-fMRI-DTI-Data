%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gradCPT Simultaneous EEG-fMRI Preprocessing Script
%
% Description:
%   This custom script preprocesses EEG data collected during the gradCPT task
%   in simultaneous EEG-fMRI experiments.
%   The workflow includes:
%       1. Loading raw EEG (.vhdr) files
%       2. Gradient artifact removal (GA) using FMRIB toolbox
%       3. Ballistocardiogram / pulse artifact removal (PA)
%       4. Saving preprocessed datasets
%       5. Spectrogram visualization for quality control
%
% Mapping to script sections:
% Step                                 | Section
% ------------------------------------ | ----------------------
% Load raw EEG data                    | Lines 60-62
% Edit channel locations               | Lines 64-65
% Determine scanner state / processing | Lines 67-74
% Gradient Artifact Removal (GA)       | Lines 76-109
% Ballistocardiogram Artifact Removal  | Lines 111-121
% Spectrogram / QC visualization       | Lines 123-135
% Save preprocessed datasets           | Lines 137-145
%
% Usage notes:
% - ANCFlag = 0 : No ANC applied
% - ANCFlag = 1 : ANC applied
% - Users must place raw EEG files in the relative folder structure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
clear all
% Use relative path for GitHub repository
file_path = './EEG/';
subj_list = dir([file_path '*_*']);
electrodeExclude = 32; % ECG channel

% Load previously saved channel information (relative path)
load('./ch_locs.mat'); 

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Main preprocessing loop
for ANCFlag = 0 % 0 : No ANC, 1: ANC applied
    for subj_no = 3 % Change to 1:length(subj_list) for all subjects
        state_list = dir([file_path subj_list(subj_no).name '/*.vhdr']);

        % Create output directories
        outputDir0 = [file_path subj_list(subj_no).name '/GAremoval_0_yh/'];
        outputDir1 = [file_path subj_list(subj_no).name '/GAremoval_1_yh/'];
        if ANCFlag == 0 && ~exist(outputDir0, 'dir')
            mkdir(outputDir0); mkdir([outputDir0 '/figure']);
            mkdir(outputDir1); mkdir([outputDir1 '/figure']);
        end

        for st_no = 6 % Change to 1:length(state_list) for all sessions
            input_fileName = state_list(st_no).name;

            %% Load raw EEG
            EEG = pop_loadbv([file_path subj_list(subj_no).name '/'], input_fileName);
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

            %% Edit channel locations
            EEG.chanlocs = ch_locs;

            %% Determine scanner condition
            if contains(input_fileName,'on')
                processing_idx = 1; % Scanner ON
            elseif contains(input_fileName,'off')
                processing_idx = 0; % Scanner OFF
            else
                processing_idx = -1; % Outside scanner
            end

            %% Gradient Artifact Removal (GA)
            EEG.data = double(EEG.data);
            if processing_idx == 1
                tr_idx = 1; tr_time = [];
                for i = 1:length(EEG.event)
                    if EEG.event(i).type(1) == 'T'
                        EEG.event(i).type = 'TR';
                        tr_time(tr_idx) = EEG.event(i).latency;
                        tr_idx = tr_idx + 1;
                    end
                end

                % Insert TR events if needed
                for tr_time_no = 1:length(tr_time)-1
                    if ((tr_time(tr_time_no+1)-1 - tr_time(tr_time_no)-1)/2)/5000 > 1
                        ave_latency = ((tr_time(tr_time_no+1)-1 + tr_time(tr_time_no)-1)/2)/5000;
                        EEG = pop_editeventvals(EEG,'insert',{1 [] [] [] [] [] [] [] [] []}, ...
                                                'changefield',{1 'latency' ave_latency}, ...
                                                'changefield',{1 'type' 'TR'}, ...
                                                'changefield',{1 'code' 'Toggle'});
                    end
                end

                % Apply FMRIB GA removal
                if ANCFlag == 0
                    output_fileSET = fullfile(outputDir0,[input_fileName(1:end-5),'_GArm_noANC','.set']);
                    EEG = pop_fmrib_fastr(EEG, [], [], 30, 'TR',0,0,[],[],[],[],electrodeExclude,0);
                else
                    output_fileSET = fullfile(outputDir1,[input_fileName(1:end-5),'_GArm_ANC','.set']);
                    EEG = pop_fmrib_fastr(EEG, [], [], [], 'TR',0,1,[],[],[],[],electrodeExclude,0);
                end
                [~, EEG, ~] = pop_newset([], EEG, 1, 'setname', [EEG.setname,' | GA Removed'], ...
                                         'savenew', output_fileSET, 'gui','off');
            end

            %% Ballistocardiogram Artifact Removal (PA)
            ecgchan = 32;
            EEG = pop_fmrib_qrsdetect(EEG, ecgchan, 'qrs', 'no');
            EEG = pop_fmrib_pas(EEG, 'qrs', 'median');
            if ANCFlag == 0
                output_fileSET = fullfile(outputDir0,[input_fileName(1:end-5),'_PArm','.set']);
            else
                output_fileSET = fullfile(outputDir1,[input_fileName(1:end-5),'_PArm','.set']);
            end
            [~, EEG, ~] = pop_newset([], EEG, 1, 'setname', [EEG.setname,' | PA Removed'], ...
                                     'savenew', output_fileSET, 'gui','off');

            %% Spectrogram / Quality Control
            ch_no = 20; % Example channel
            tmp_data = double(EEG.data);
            tmp_data(isnan(tmp_data)) = 0;

            NFFT = 100000; sf = 5000; window = 10000; overlap = round(4*window/5);
            [b, F, T, P] = spectrogram(tmp_data(ch_no,:), window, overlap, NFFT, sf);

            figure1_a = figure;
            set(figure1_a, 'Units','centimeters','Color','white','Position',[20 10 25 15]);
            imagesc(smooth2a(log(abs(b(1:601,:))),1), [5 13]); axis xy; colormap(jet);
            xlabel('Time (sec)','fontsize',14); ylabel('Frequency','fontsize',14);
            title(strrep(input_fileName(1:end-5),'_',' '),'fontsize',14);

            if ANCFlag == 0
                print(figure1_a,'-dtiffn','-r300',[outputDir0 '/figure/' input_fileName(1:end-5)]);
            else
                print(figure1_a,'-dtiffn','-r300',[outputDir1 '/figure/' input_fileName(1:end-5)]);
            end
            close gcf
        end % st_no
    end % subj_no
end % ANCFlag
