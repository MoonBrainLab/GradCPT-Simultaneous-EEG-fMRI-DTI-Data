% For the simultaneous EEG-fMRI music project
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Load raw EEG data
% 2. Remove GA and prs artifacts using fmrib toolbox
% 3. Save preprocessed data set
% 4. Plot and save topoplot and spectrogram to check data quality
%
% Revision
% 1) Run in both conditions when ANCFlag is 0 and 1
% 2) Run Gradient artifact removal only in ON condition. 
%
% 2023. 03. 07. Hyoungkyu Kim
% 2023. 03. 20. Younghwa Cha(Revision)
% 2023. 04. 03. Hyoungkyu Kim : insert TR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
% change file path
clear all
file_path='D:\Dropbox\Moonbrainlab\Music Project\EEG\';
subj_list = dir([file_path '*_*']);
electrodeExclude = 32; % ECG channel

% load previously saved channel information file
load('D:\Dropbox\Moonbrainlab\EEG-fMRI_experiments\ch_locs.mat');
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% run all the process in both condition when ANCFlag is 0 and 1
for ANCFlag=0%:1% 0 : No ANC, 1: ANC

    for subj_no=6%1:length(subj_list)
        state_list = dir([file_path subj_list(subj_no).name '/*.vhdr' ]);

        % make two folders for ANCFlag is 0 and 1
        outputDir0 = [file_path subj_list(subj_no).name '/GAremoval_0_yh/'];
        outputDir1 = [file_path subj_list(subj_no).name '/GAremoval_1/'];
    
        for st_no=2:length(state_list) % from 1 until the end of task
            input_fileName = state_list(st_no).name; % full name of all tasks
            
            if ANCFlag==0
                if st_no==1
                    mkdir([outputDir0])
                    mkdir([outputDir0 '/figure'])
                    mkdir([outputDir1])
                    mkdir([outputDir1 '/figure'])    
                end % if  
            end
    
            % load brain vision raw data using vhdr file
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            EEG = pop_loadbv([file_path subj_list(subj_no).name '/'], state_list(st_no).name);
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            % eeglab redraw
    
            % edit channel location 
            EEG.chanlocs = ch_locs;
    
            tmp_name=state_list(st_no).name; % same name as input_fileName
            if contains(tmp_name,'_on') == 1  % scanner ON
            % if contains(tmp_name,'fMRI') == 1  % fMRI    
                processing_idx = 1;
            elseif contains(tmp_name,'_off') == 1 % scanner OFF
                processing_idx = 0;
%             elseif contains(tmp_name,'out') == 1
%                 processing_idx = -1; % outside of scanner
            else 
                processing_idx = 1; % 
            end

            start_latency = 159095; 
            end_latency = 685741;
            EEG = pop_select(EEG, 'point', [start_latency end_latency]);

    
            %% Gradient Artifact Removal
            EEG.data = double(EEG.data);
            
            % run Gradient artifact removal only in ON condition
            if (processing_idx==1) %|| (processing_idx==0)
                tr_idx=1;
                tr_time=[];
                if processing_idx == 1
                    for i=1:length(EEG.event)
                        tmp=EEG.event(i).type;
                        if tmp(1) == 'T'
                            EEG.event(i).type = 'TR';
                            tr_time(tr_idx)=EEG.event(i).latency;
                            tr_idx=tr_idx+1;
                        end % if
                    end % i

                    for tr_time_no=1:length(tr_time)-1
                        if ((tr_time(tr_time_no+1)-1 - tr_time(tr_time_no)-1)/2)/5000 > 1
                            ave_latency = ((tr_time(tr_time_no+1)-1 + tr_time(tr_time_no)-1)/2)/5000;
                            EEG = pop_editeventvals(EEG,'insert', { 1 [] [] [] [] [] [] [] [] []}, 'changefield',{1 'latency' ave_latency}, 'changefield',{1, 'type', 'TR'} , 'changefield',{1, 'code', 'Toggle'} ); 
                        end
                    end % tr_time_no
                end % if

    
                    % period rejection berfore scan on
                   EEG = eeg_eegrej( EEG, [1 tr_time(2)]);
%     
%             elseif processing_idx == 0
%                 for i=1:length(EEG.event)
%                     tmp=EEG.event(i).type;
%                     if contains(tmp,'Sync On') == 1 
%                         EEG.event(i).type = 'TR';
%                     end % if
%                 end % i
        
                if (ANCFlag == 0)
                    output_fileSET = fullfile(outputDir0,[input_fileName(1:length(input_fileName)-5),'_GArm_noANC','.set']);
                    EEG = pop_fmrib_fastr(EEG,[],[],[],'TR',0,0,[],[],[],[],electrodeExclude,0);
                    % EEG = pop_fmrib_fastr(EEG,[],[],[],'TR',1,0,[],[],[],[],electrodeExclude,'auto');
                    [~,EEG,~] = pop_newset([], EEG, 1,'setname',[EEG.setname,' | GA Removed (no ANC)'],'savenew',output_fileSET,'gui','off');
                elseif (ANCFlag == 1)
                    output_fileSET = fullfile(outputDir1,[input_fileName(1:length(input_fileName)-5),'_GArm_ANC','.set']);
                    EEG = pop_fmrib_fastr(EEG,[],[],[],'TR',0,1,[],[],[],[],electrodeExclude,0);
                    [~,EEG,~] = pop_newset([], EEG, 1,'setname',[EEG.setname,' | GA Removed (ANC)'],'savenew',output_fileSET,'gui','off');
                end
            end % if processing_idx ==1
            
            ecgchan = 32;

            % divide files into two folders (but the same name '_PArm')
            if ANCFlag==0
                output_fileSET = fullfile(outputDir0,[input_fileName(1:length(input_fileName)-5),'_PArm','.set']);
            elseif ANCFlag==1
                output_fileSET = fullfile(outputDir1,[input_fileName(1:length(input_fileName)-5),'_PArm','.set']);
            end

            EEG = pop_fmrib_qrsdetect(EEG,ecgchan,'qrs','no');
            EEG = pop_fmrib_pas(EEG,'qrs','median');
            [~,EEG,~] = pop_newset([], EEG, 1,'setname',[EEG.setname,' | PA Removed'],'savenew',output_fileSET,'gui','off');
    
            % Spectrogram
            ch_no=20; % [20 9 10 31 59 60];
            tmp_data=double(EEG.data);
            
            time_min=1; % 100*sf
            time_max=length(tmp_data); % 192*sf;
            tmp_data(isnan(tmp_data))=0;
            NFFT=100000; sf=5000; window=10000; overlap=round(4*window/5); 
            
            [b, F ,T, P]=spectrogram( tmp_data(ch_no,time_min:time_max),window,overlap,NFFT,sf);
            
            figure1_a=figure;
            set (figure1_a, 'resize','off')
            % set (figure1_a,'DefaultTextFontName','Arial','DefaultTextFontSize',10, 'DefaultTextFontWeight','Normal');
            % set (figure1_a, 'DefaultAxesFontSize', 12, 'DefaultAxesFontName', 'Arial', 'DefaultAxesFontWeight','Normal');
            % set (gca, 'FontName', 'Arial', 'FontSize', 12);
            set (figure1_a, 'Units', 'centimeters', 'Color', 'white');   % whole figure size control
                        %         pos = [0 0 20 10];
            pos = [20 10 25 15];  % [0 0 40 24];
            set(figure1_a, 'Position', pos, 'Units', 'centimeters');
            % set(figure1_a, 'PaperPositionMode', 'auto')     
    
            imagesc( smooth2a(log(abs(double(b(1:601,:)))),1), [5 13]), axis xy, colormap(jet)
            
                set(gca,'FontSize',12,'YTick',[1 101 201 241 301 401 501 601],'YTickLabel', {'0','5','10','12', '15','20','25','30'});
                set(gca,'FontSize',12,'XTick',[1:50:size(b,2)],'XTickLabel', [0:20:400]); % {'1','5','10','15','20','25','30','35'}
                ylabel('Frequency', 'fontsize', 14)
                xlabel('Time (sec)', 'fontsize', 14)
                new_name = strrep(input_fileName(1:length(input_fileName)-5),'_',' ');
                title([new_name], 'fontsize', 14)
            
            if ANCFlag==0
                print(figure1_a,'-dtiffn', '-r300', [outputDir0 '/figure/' input_fileName(1:length(input_fileName)-5)])
            elseif ANCFlag==1
                print(figure1_a,'-dtiffn', '-r300', [outputDir1 '/figure/' input_fileName(1:length(input_fileName)-5)])
            end    
            
            close gcf 
    
        end % st_no
            
    end % subj_no

end % ANCFlag

%ANCFlag = 0
%file_path ='/home/yeji/research/Dropbox/Moonbrainlab/EEG-fMRI_experiments/gradCPT_main/EEG/cpt25_230809'
% outputDir0 = [file_path '/GAremoval_0_yh/'];
%input_fileName='cpt25_ses06_gradcpt1_on.vhdr'


