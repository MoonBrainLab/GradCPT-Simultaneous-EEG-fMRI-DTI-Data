%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% gradCPT_withinSubject1.m
% GradCPT is performed with a within-subject design (Jihyang, Sep 23, 2018)
% Eight 4-min blocks with 30-sec rest between blocks

% Factor 1: Visual onset. For half of blocks, stimuli are presented with a
% gradual onset as in the standard gradCPT paradigm; for the other half, stimuli are
% presented with an abrupt onset as in most of attention paradigms.

% Factor 2: Required response rate. For half of blocks, required response
% rate is 90%; for the other half, it is 10%.

% Counterbalancing task: For half of particiants, task is to press "c" to city; the other half
% should press "m" to mountain.
% Counterbalancing the order of blocks: ABCD - DCBA. The 2 (visual onset:
% gradual vs. abrupt) x 2 (required response rate: 90% vs. 10%) blocks are
% randomly distributed to the four blocks, ABCD.
% The random orders of the ABCD (24 possible cases) will be also
% counterbalced across 24 participants pressing "c" and across 24 participants
% pressing "m."

% Experiment parameters
% When images had a gradual onset, images transitioned every 800 msec, as
% in Esterman et al. (2013, Cerebral Cortex),
%
% When images had an abrupt onset, images also transitioned every 800 msec.
% Stimulus duration is 560 msec; Blank interval between images is 240 msec.
% The duration and the interval are calculated based on our criterion for
% unambiguous responses (i.e., responses made before 70% coherence or after
% 40% coherence while the image in the n trial was presented)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Experimental parameters
clear all;
rand('state', sum(100*clock));
Screen('Preference', 'SkipSyncTests', 1);
set_default_light;
KbName('UnifyKeyNames');
fKey=KbName('f');
Key_c = KbName('c'); Key_m = KbName('m');
Key_1 = KbName('1!'); Key_4 = KbName('4$');
spaceKey = KbName('space'); escKey = KbName('ESCAPE');
corrkey = 98; % correspond to 0 on the number board
gray = [127 127 127]; white = [255 255 255]; black = [0 0 0];
bgcolor = white; textcolor = black;
beep = MakeBeep(1000,.05); Snd('Open');
%JJ temporarily changed this
miss_num = '1'; fa_num = '2';
%% Login prompt and open file for writing data out
prompt = {'Outputfile', 'Participant Number:', 'Age', 'Gender', 'Num of blocks', 'Press', 'Is this for practice? (y or n)', 'Pilot: Number of trials?' 'Pilot: BreakTime? (sec)' 'Pilot: Skip the auditory instruction? (y or n)'};
defaults = {'20230417', '01', '29', 'F', '1' , 'c', 'n', '450', '0', 'n'};
answer = inputdlg(prompt, 'gradCPT_WithinSub1_', 2, defaults);
[output, subid, subage, gender, nBlocks, PressType, practice, temp_numTrial, BreakTime, auditorySkip] = deal(answer{:}); % all input variables are strings
temp_numTri = str2num(temp_numTrial);
if practice == 'y'
    practice_con = 'Practice'; nBlocks = '4';
    if temp_numTri == 300 
        temp_numtri = 30;
    else
        temp_numtri = temp_numTri;
    end
else
    practice_con = 'Main';
    if temp_numTri < 300 
        temp_numtri = temp_numTri;
    else
        temp_numtri = temp_numTri;
    end
end

outputname = [output practice_con subid gender nBlocks subage PressType '.xls'];
nblocks = str2num(nBlocks); % convert string to number for subsequent reference
subID = str2num(subid);
subAge = str2num(subage);
breaktime = str2num(BreakTime);

if gender == 'F'
    gender_num = 9;
elseif gender == 'M'
    gender_num = 16;
end

if auditorySkip == 'y'
    pilot_audio = 0;
else
    pilot_audio = 1;
end

if exist(outputname)==2 % check to avoid overiding an existing file
    fileproblem = input('That file already exists! Append a .x (1), overwrite (2), or break (3/default)?');
    if isempty(fileproblem) | fileproblem==3
        return;
    elseif fileproblem==1
        outputname = [outputname '.x'];
    end
end

if PressType == 'c' 
    Key1 = Key_1; press = 'city'; nopress = 'mountain';
elseif PressType == 'm'
    Key1 = Key_4; press = 'mountain'; nopress = 'city';
end

%% load images
imnum_city = 10; imnum_moun = 10;
for i = 1:imnum_city
    imgName = ['Stimuli/city' num2str(i) '.png'];
    x = imread(imgName);
    y = x;
    [nPixelx nPixely nColor] = size(x);
    im_city(:,:,i) = y;
end
x = []; y = []; i = [];

for i = 1:imnum_moun
    imgName = ['Stimuli/mountain' num2str(i) '.png'];
    x = imread(imgName);
    y = x;
    [nPixelx nPixely nColor] = size(x);
    im_moun(:,:,i) = y;
end
x = []; y = []; i = [];

%% make matrix
freqratio = .9; rareratio = .1;
expmat = []; samplesize = 48;
order = [1 2 3 4]; order_perm = repmat(perms(order),2,1);
if subID <= samplesize
    subid = subID;
else
    id_rand = randperm(samplesize); subid = id_rand(1);
end
first_order = order_perm(subid,:);
order = [first_order, flip(first_order)];
if practice == 'y'
    order = [first_order];
end
%trial_blo = 50; %temp
feedback_data_temp =[];
trial_blo = 300; 
trial_freq = trial_blo*freqratio; trial_rare = trial_blo*rareratio;
% When response rate is .9, 270 trials are to be pressed; 30 trials are skipped.
% When response rate is .1, 30 trials are to be pressed.
if PressType == 'c'
    presstype = 6; [y,Fs] = audioread('Instruction_City.m4a');
elseif PressType == 'm'
    presstype = 16;[y,Fs] = audioread('Instruction_Mountain.m4a'); 
end

for i = 1:length(order) % 8 blocks    
    blockType = order(i); %1~4
    if i <= 4
        blockRepeatNum = 1;
    else
        blockRepeatNum = 2;
    end
    
    if blockType == 1 %A
        blockCon = 1; ResponseRate = 90; onset = 10; %onset 10 is gradual
    elseif blockType == 2 %B
        blockCon = 2; ResponseRate = 90; onset = 10; %onset 4 is abrupt
    elseif blockType == 3 %C
        blockCon = 3; ResponseRate = 90; onset = 10;
    elseif blockType == 4 %D
        blockCon = 4; ResponseRate = 90; onset = 10;        
    end
    
    expseq_freq = []; expseq_rare = [];
    pick = randperm(10); % 10 images    
    for j = 1:(trial_freq/length(pick)) % 300 trials per block
        set1 = [pick(1), Shuffle(pick(3:10)), pick(2)];
        set2 = [pick(3), Shuffle(pick(5:10)), Shuffle(pick(1:2)), pick(4)];
        set3 = [pick(5), Shuffle(pick(7:10)), Shuffle(pick(1:4)), pick(6)];
        set4 = [pick(7), Shuffle(pick(9:10)), Shuffle(pick(1:6)), pick(8)];
        set = [set1;set2;set3; set4]; set_pick = randperm(4);
        freq_seq = set(set_pick(1),:);
        expseq_freq = [expseq_freq;freq_seq'];
    end    
    
    for k = 1:(trial_rare/length(pick))
        set1 = [pick(1), Shuffle(pick(3:10)), pick(2)];
        set2 = [pick(3), Shuffle(pick(5:10)), Shuffle(pick(1:2)), pick(4)];
        set3 = [pick(5), Shuffle(pick(7:10)), Shuffle(pick(1:4)), pick(6)];
        set4 = [pick(7), Shuffle(pick(9:10)), Shuffle(pick(1:6)), pick(8)];
        set = [set1;set2;set3; set4]; set_pick = randperm(4);
        rare_seq = set(set_pick(1),:);
        expseq_rare = [expseq_rare;rare_seq'];      
    end
    expseq_freq_temp = [expseq_freq, repmat(9,[length(expseq_freq),1])]; % 9 means pressed-frequent trials
    expseq_rare_temp = [expseq_rare, repmat(21,[length(expseq_rare),1])]; % 21 means pressed-rare trials
    pick_rare = randperm(trial_blo);
    rareTriNum = pick_rare(1:trial_rare);
    r = 1; f = 1; expseq = [];
    for m = 1:trial_blo
        checkTri = find(rareTriNum == m);
        if checkTri > 0 % rare image trials
            expseq_temp = expseq_rare_temp(r,:);
            r = r+1;
        else % frequent image trials
            expseq_temp = expseq_freq_temp(f,:);
            f= f+1;
        end
        expseq = [expseq;expseq_temp];
    end
    %expseq_temp = [expseq_temp1; expseq_temp2];
    %expseq = expseq_temp(randperm(size(expseq_temp,1)),:);
    
    for l = 1:trial_blo
        imgNum = expseq(:,1);
        imgTypeSet = expseq(:,2); % 9 means 'frequent' images; 21 means 'rare' images
        
        if imgTypeSet(l) == 9 % frequent image trials
            if ResponseRate == 90 && PressType == 'c'            
                imgType = 6; %imgType 6 is city; 16 is mountain
            elseif ResponseRate == 90 && PressType == 'm'            
                imgType = 16;           
            elseif ResponseRate == 10 && PressType == 'c'            
                imgType = 16;   
            elseif ResponseRate == 10 && PressType == 'm'            
                imgType = 6;             
            end % blockCon = 'a'; ResponseRate = .9; onset = 'g';
            
        elseif imgTypeSet(l) == 21 % rare image trials
            if ResponseRate == 90 && PressType == 'c'            
                imgType = 16; %imgType 6 is city; 16 is mountain
            elseif ResponseRate == 90 && PressType == 'm'            
                imgType = 6;           
            elseif ResponseRate == 10 && PressType == 'c'            
                imgType = 6;   
            elseif ResponseRate == 10 && PressType == 'm'            
                imgType = 16;             
            end
            
        end
        expmat = [expmat; presstype, blockCon,blockRepeatNum,ResponseRate,onset,i,l,imgType,imgNum(l)];
    end
end

%% Open a file for writing data out
outfile = fopen(outputname,'w'); % open a file for writing data out
fprintf(outfile, 'subID\t subAge\t gender\t pressTask\t blockType\t blockRepeatNum\t ResponseRate\t OnsetType\t blockNum\t trialNum\t imageCategory\t imageNumber\t RT\t Pressed\t transitionNum\t \n');
seqFileName = ['gradCPT_WithinSub1_Subnum' subid 'seqFile'];

%% Screen parameters
screens = Screen('Screens');
Screen_no = max(screens);
[mainwin, screenrect] = Screen(Screen_no, 'OpenWindow', []);
Screen('FillRect', mainwin, bgcolor);
center = [screenrect(3)/2 screenrect(4)/2];
Screen(mainwin, 'Flip');
left = center(1)-400;

%% instruction
if practice == 'y'
    HideCursor();
    Screen('FillRect', mainwin ,bgcolor);
    Screen('TextSize', mainwin, 36);
    Screen('DrawText', mainwin, ['Welcome to sustaining attention task. Now you will begin a practice session first.'], left, center(2)-200, textcolor);
    Screen('DrawText', mainwin, ['You will be shown a rapid sequence of black and white scenes.'], left, center(2)-140, textcolor);
    Screen('DrawText', mainwin, ['Please categorize every scene as either a city or a mountain.'], left, center(2)-110, textcolor);
    Screen('DrawText', mainwin, ['Please press the key ' PressType ' upon seeing a ', press, ' scene'], left, center(2)-80, textcolor);
    Screen('DrawText', mainwin, ['Make no response when you see a ' nopress, ' scene'], left, center(2)-50, textcolor);
    Screen('DrawText', mainwin, ['Press the spacebar to continue.'], left, center(2)+10, textcolor);

    Screen('Flip', mainwin);   
    keyIsDown=0;
    while 1
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(spaceKey)
                break ;
            elseif keyCode(escKey)
                ShowCursor;
                fclose(outfile);
                Screen('CloseAll');
                return;
            end
        end
    end
    WaitSecs(0.3);

    Screen('DrawText', mainwin, ['In the main task,'], left, center(2)-170, textcolor);
    Screen('DrawText', mainwin, ['Every sequence will last about 4 minutes.'], left+20, center(2)-140, textcolor);
    Screen('DrawText', mainwin, ['You will rest for 30 seconds before resuming the next sequence.'], left+20, center(2)-110, textcolor);
    Screen('DrawText', mainwin, ['There will be 8 sequences for a total of about 32  minutes.'], left+20, center(2)-80, textcolor);

    Screen('DrawText', mainwin, ['However, as this is only for practice,'], left, center(2)+10, textcolor);
    Screen('DrawText', mainwin, ['Every sequence will last only 30 seconds.'], left+20, center(2)+40, textcolor);
    Screen('DrawText', mainwin, ['You will rest for 5 seconds before resuming the next sequence.'], left+20, center(2)+70, textcolor);
    Screen('DrawText', mainwin, ['There will be 4 sequences for a total of about 1  minute.'], left+20, center(2)+100, textcolor);
    Screen('DrawText', mainwin, ['Press the spacebar to start when you are ready.'], left+20, center(2)+160, textcolor);

    Screen('Flip', mainwin);   
    keyIsDown=0;
    while 1
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(spaceKey)
                break ;
            elseif keyCode(escKey)
                ShowCursor;
                fclose(outfile);
                Screen('CloseAll');
                return;
            end
        end
    end
    WaitSecs(0.3);    
    
else
    HideCursor();
    Screen('FillRect', mainwin ,bgcolor);
    Screen('TextSize', mainwin, 36);
    Screen('DrawText', mainwin, ['Now we will begin the main task.'], left, center(2)-200, textcolor);
    Screen('DrawText', mainwin, ['You will be shown a rapid sequence of black and white scenes.'], left, center(2)-140, textcolor);
    Screen('DrawText', mainwin, ['Please categorize every scene as either a city or a mountain.'], left, center(2)-110, textcolor);
    Screen('DrawText', mainwin, ['Please press the key ' PressType ' upon seeing a ', press, ' scene'], left, center(2)-80, textcolor);
    Screen('DrawText', mainwin, ['Make no response when you see a ' nopress, ' scene'], left, center(2)-50, textcolor);
    Screen('DrawText', mainwin, ['In this part, a sequence will last about 6 minutes.'], left, center(2)+10, textcolor);
    Screen('DrawText', mainwin, ['You will then get a break before resuming the next sequence.'], left, center(2)+40, textcolor);
  %  Screen('DrawText', mainwin, ['There will be 8 sequences for a total of about 32  minutes.'], left, center(2)+70, textcolor);
    Screen('DrawText', mainwin, ['Press the spacebar to start when you are ready.'], left, center(2)+130, textcolor);

    Screen('Flip', mainwin);   
    keyIsDown=0;
    while 1
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(spaceKey)
                break ;
            elseif keyCode(escKey)
                ShowCursor;
                fclose(outfile);
                Screen('CloseAll');
                return;
            end
        end
    end
    WaitSecs(0.3);
end

%% start
% condition parameters
numOfTransitions = 16; grad_trialDur = 800; weightImg = linspace(0,1,numOfTransitions);
abr_stiDur = .56; abr_interval = .24;
% Stimulus duration is .56(560 msec); Blank interval between images is .24(240 msec).
feedback_data = [];
for b = 1:length(order)
    immat={};
    row_first = 1+(b-1)*trial_blo; row_last = row_first+trial_blo-1;
    expmat_b = expmat(row_first:row_last,:);
    
    pressCon = expmat_b(1,1);
    blockCondition = expmat_b(1,2); %1~4 corresponds to a~d
    blockRepNum = expmat_b(1,3); %1(first) or 2(second)
    responseRate = expmat_b(1,4); %required response rate: 0.1 or 0.9
    visualonset = expmat_b(1,5); %onset 10 is gradual; onset 4 is abrupt
    press_totalnum = 0;
    nopress_totalnum = 0;
    %% Each block begins
    %% gradual-onset
    if visualonset == 10 % gradual onset  
        for t = 1:length(expmat_b) %% load images
            imgCat = expmat_b(t,8);
            imageNum = expmat_b(t,9);
            if imgCat == 6 %imgType 6 is city; 16 is mountain
                im1 = im_city(:,:,imageNum);
            elseif imgCat == 16 %16 is mountain
                im1 = im_moun(:,:,imageNum);
            end
            
            if t > 1
                imgCat_pre = expmat_b(t-1,8);
                imageNum_pre = expmat_b(t-1,9);
            elseif t == 1
                imgCat_pre = expmat_b(t+3,8);      
                imageNum_pre = expmat_b(t+3,9);
            end
            
            if imgCat_pre == 6 % city
                im2 = im_city(:,:,imageNum_pre);
            elseif imgCat_pre == 16 % mountain
                im2 = im_moun(:,:,imageNum_pre);
            end            
            immat{t,1} = im1; immat{t,2} = im2;
        end       
        
        %% Press spacebar to start
         if pilot_audio == 0
         else
            sound(y,Fs);
            Screen('DrawText', mainwin, ['Please press the letter ' PressType ' upon seeing a ', press, ' scene'], left, center(2), textcolor);
            Screen('Flip',mainwin );
            WaitSecs(6);
         end
        Screen('DrawText', mainwin, ['Please press the letter ' PressType ' upon seeing a ', press, ' scene'], left, center(2), textcolor);
        Screen('DrawText', mainwin,['Press spacebar to start!'], left, center(2)+60,textcolor);
        Screen('Flip',mainwin );
        keyIsDown=0;
        while 1
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(spaceKey)
                    break ;
                elseif keyCode(escKey)
                    ShowCursor;
                    fclose(outfile);
                    Screen('CloseAll');
                    return;
                end
            end
        end
        WaitSecs(0.3);
      
        %% show images
        StartMovieTime = GetSecs;
        if temp_numtri < 300
            length_mat = temp_numtri;
        else
            length_mat = length(expmat_b);
        end

        send_daqevent(daq_id, daq.begin, setting_id);
        tic
        for s = 1:length_mat % show images     
           
            imgCategory = expmat_b(s,8); imageNum = expmat_b(s,9); % from here
            startTime1 = GetSecs;
            remainingDur = grad_trialDur - (GetSecs-startTime1).*1000;
            durEachImage = (remainingDur./numOfTransitions./1000);
            previousRT = 0; responded=0; keyIsDown=0; rt = 0; keypressed=-1;keyCode=0; trialRecorded=0;
            im1 = immat{s,1}; im2 = immat{s,2};
            
            send_daqevent(daq_id, daq.stimulus, setting_id);
            for j = 1:numOfTransitions
                startTime2 = GetSecs;
                gradImage(:,:,j) = im1.*weightImg(j) + im2.*(1-weightImg(j));               
                currentImage = Screen('MakeTexture', mainwin, gradImage(:,:,j));
                Screen('DrawTexture', mainwin, currentImage, [], [center(1)-nPixelx./1, center(2)-nPixelx./1, center(1)+nPixelx./1, center(2)+nPixelx./1,]);
                Screen('Flip', mainwin);
                lostTime = GetSecs-startTime2;
                keyIsDown=0; rt = 0; keypressed=-1;keyCode=0;
                while GetSecs-startTime2 < durEachImage-lostTime
                    FlushEvents('keyDown');
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyIsDown
                        nKeys = sum(keyCode);
                        if nKeys==1
                            if keyCode(Key1)
                                rt = 1000.*(GetSecs-startTime1);
                                keypressed=find(keyCode); responded=1;
                                break;
                            elseif keyCode(escKey)
                                ShowCursor; fclose(outfile); ShowCursor(); Screen('CloseAll'); return
                            end

                        end
                    end
                end
                
                if (previousRT>0 && rt > previousRT+200) || (j == numOfTransitions && responded == 0) || (previousRT==0 && rt > 0)
                    fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                        subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j);                                      
                    feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
                    previousRT = rt; rt = 0; trialRecorded=1;
                end
                while GetSecs-startTime2 < durEachImage
                end                  
            end
            send_daqevent(daq_id, daq.end, setting_id);

                if trialRecorded==0
                    fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                        subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j);     
                    feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
                end       
                GetSecs-startTime1
                
            if pressCon-imgCategory == 0 % press trial
                press_totalnum = press_totalnum + 1;
            else
                nopress_totalnum = nopress_totalnum + 1;
            end
            
        end
        toc
        send_daqevent(daq_id, daq.endend, setting_id);   

    %% abrupt-onset
    elseif visualonset == 4 % abrupt onset       
        for t = 1:length(expmat_b)
            imgCat = expmat_b(t,8);
            imageNum = expmat_b(t,9);
            if imgCat == 6 %city
                im1 = im_city(:,:,imageNum);
            elseif imgCat == 16 % mountain
                im1 = im_moun(:,:,imageNum);
            end
            immat{t,1} = im1;
        end        

         %% Press spacebar to start
         if pilot_audio == 0
         else
            sound(y,Fs);
            Screen('DrawText', mainwin, ['Please press the letter ' PressType ' upon seeing a ', press, ' scene.'], left, center(2), textcolor);
            Screen('Flip',mainwin );
            WaitSecs(6);
         end
        Screen('DrawText', mainwin, ['Please press the letter ' PressType ' upon seeing a ', press, ' scene.'], left, center(2), textcolor);
        Screen('DrawText', mainwin,['Press spacebar to start!'], left, center(2)+60,textcolor);
        Screen('Flip',mainwin );  
        keyIsDown=0;
        while 1
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(spaceKey)
                    break ;
                elseif keyCode(escKey)
                    ShowCursor;
                    fclose(outfile);
                    Screen('CloseAll');
                    return;
                end
            end
        end
        WaitSecs(0.3); [stamp0, onset0] = Screen('Flip', mainwin);        
 
        if temp_numtri < 300
            length_mat = temp_numtri;
        else
            length_mat = length(expmat_b);
        end
        
        for s = 1:length_mat
            % stimulus presented
            imgCategory = expmat_b(s,8); imageNum = expmat_b(s,9);
            responded = 0;            
            trialRecorded = 0;
            im1 = immat{s,1}; 
            curImg = Screen('MakeTexture', mainwin, im1);
            Screen('DrawTexture', mainwin, curImg, [], [center(1)-nPixelx./2, center(2)-nPixelx./2, center(1)+nPixelx./2, center(2)+nPixelx./2,]);
            Screen('Flip', mainwin);
            startTime3 = GetSecs;
            lostTime = GetSecs-startTime3;
            GetSecs; keyIsDown=0; rt = 0; keypressed=-1;keyCode=0;
            while GetSecs-startTime3 < abr_stiDur-lostTime
                FlushEvents('keyDown');
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    nKeys = sum(keyCode);
                    if nKeys==1
                        if keyCode(Key1)
                            rt = 1000.*(GetSecs-startTime3);
                            keypressed=find(keyCode); responded=1;
                            break;
                        elseif keyCode(escKey)
                            ShowCursor; fclose(outfile); ShowCursor(); Screen('CloseAll'); return
                        end

                    end
                end
            end
            
            if responded == 1
                fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                    subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, -1); %transition 190                               
                feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
                rt = 0; trialRecorded=1;
            end     
            
            while GetSecs-startTime3 < abr_stiDur
            end   
            
            if responded == 0
                fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                    subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, -1); %transition 190                 
                feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
            end
            
            % blank interval
            responded = 0;
            startTime4 = GetSecs;
            trialRecorded = 0;            
            Screen('Flip', mainwin);
            startTime1 = GetSecs;
            lostTime = GetSecs-startTime4;
            GetSecs; keyIsDown=0; rt=0; keypressed=-1;keyCode=0;
            while GetSecs-startTime4 < abr_interval-lostTime
                FlushEvents('keyDown');
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    nKeys = sum(keyCode);
                    if nKeys==1
                        if keyCode(Key1)
                            rt = 1000.*(GetSecs-startTime1) + 1000.*abr_stiDur;
                            keypressed=find(keyCode); responded=1;
                            break;
                        elseif keyCode(escKey)
                            ShowCursor; fclose(outfile); ShowCursor(); Screen('CloseAll'); return
                        end

                    end
                end
            end
            
            if responded == 1
                fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                    subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, -1); %transition 190                 
                feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
                rt = 0; trialRecorded=1;
            end     
            
            while GetSecs-startTime4 < abr_interval
            end   
            
            if responded == 0
                fprintf(outfile, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %6.2f\t %d\t %d\t \n', ...
                    subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, -1); %transition 190                 
                feedback_data = [feedback_data; subID, subAge, gender_num, pressCon, blockCondition, blockRepNum, responseRate, visualonset, b, s, imgCategory, imageNum, rt, keypressed, j];
            end
            
            if pressCon-imgCategory == 0 % press trial
                press_totalnum = press_totalnum + 1;
            else
                nopress_totalnum = nopress_totalnum + 1;
            end        
            
        end
    end
    
    %% feedback 
    miss_count = 0; fa_count = 0;
    press_count = 0; nopress_count = 0;
    
    add_columns = 2;
    [nLines nVariables] = size(feedback_data); 
    V = zeros(nLines,add_columns);
    allBlockData = feedback_data;
    lastTrial = allBlockData(nLines, 10);
    trialDur = 800;
    coherenceCutOff = [.70 .40]; % 11 corresponds to about 70%(560ms), about 40%(320ms) 
    RTCutOff = [trialDur.*coherenceCutOff(1), trialDur.*coherenceCutOff(2)+trialDur];
    RTCutOff_abrupt = [100 50];
    TotalBlock = 1; block = 1;
    block_seq = [];
    for block_s = 1:TotalBlock
        block_seq = [block_seq; repmat(block_s, [lastTrial,1])];
    end
    newData(:,5) = block_seq;
    newData(:,6) = repmat((1:lastTrial)',[TotalBlock,1]); % trialNum    
    newData = zeros(lastTrial*TotalBlock, nVariables);
    newData(:,1) = allBlockData(1,1); % subject number
    newData(:,2) = allBlockData(1,2); % subject age
    newData(:,3) = allBlockData(1,3); % subject gender
    press_condition = allBlockData(1,4); % press condition
    subid = allBlockData(1,1); %subID = num2str(subid);
    subAge = allBlockData(1,2);
    gender = allBlockData(1,3);    
    curBlockData = feedback_data;
    firstResponseIndex_EB = find(diff(curBlockData(:,10))==1)+1; % first response of a trial
    repeatResponseIndex_EB = find(diff(curBlockData(:,10))==0)+1; % multiple responses of a trial
    [numRepeatResponses_EB, junk] = size(repeatResponseIndex_EB); 
    firstResponseIndex_EB = [1; firstResponseIndex_EB];
    s = lastTrial*(block-1)+1; e = lastTrial*block;  
    imageNum_EB = curBlockData(firstResponseIndex_EB,12); % image number 1-10 is "press" trial, 11-20 is "no response" trial
    imageCat_EB = curBlockData(firstResponseIndex_EB,11); % image type: city (99) or mountain (109)    
    onsetType_EB = curBlockData(firstResponseIndex_EB,8);
    blockrepeat_EB = curBlockData(firstResponseIndex_EB,6);
    blockNum_EB = curBlockData(firstResponseIndex_EB,9);
    blockType_EB = curBlockData(firstResponseIndex_EB,5);
    trialNum_EB = curBlockData(firstResponseIndex_EB,10);
    responseRate_EB = curBlockData(firstResponseIndex_EB,7);    
    curRT = curBlockData(:,13);
    trial = curBlockData(:,10);    
    EachBlockData{block} = curBlockData;    
    EachBlockRT{block} = curRT;
    EachBlockFRI{block} = firstResponseIndex_EB;
    EachBlockRRI{block} = repeatResponseIndex_EB;
    EachBlocknumRR{block} = numRepeatResponses_EB;
    EachBlockimageNum{block} = imageNum_EB;
    EachBlockimageCat{block} = imageCat_EB;
    EachBlockOnset{block} = onsetType_EB;
    EachBlockRepeatNum{block} = blockrepeat_EB;
    EachBlockNum{block} = blockNum_EB;
    EachBlockType{block} = blockType_EB;
    EachBlocktrialNum{block} = trialNum_EB;
    EachBlockresponseRate{block} = responseRate_EB;
    block_fb = 1;

    subData_curBlock = EachBlockData{block_fb};
    RT_curBlock = EachBlockRT{block_fb};
    newRT = zeros(1, lastTrial)';
    firstResponseIndex= EachBlockFRI{block_fb};
    repeatResponseIndex = EachBlockRRI{block_fb};
    numRepeatResponses = EachBlocknumRR{block_fb};
    imageNum = EachBlockimageNum{block_fb};
    imageCat = EachBlockimageCat{block_fb};    
    onsetType = EachBlockOnset{block_fb};
    blockRepNum = EachBlockRepeatNum{block_fb};
    blockNum = EachBlockNum{block_fb};
    blockType = EachBlockType{block_fb};
    trialNum = EachBlocktrialNum{block_fb};
    responseRate = EachBlockresponseRate{block_fb};    
    if onsetType == 10 % gradual
        % first trial
        if RT_curBlock(1) > 0 % first response
            newRT(1) = RT_curBlock(1);
        else  % no response during the 800ms, check the next response
            if RT_curBlock(firstResponseIndex(2)) < RTCutOff(2) && RT_curBlock(firstResponseIndex(2)) > 0 % assign this to the first response
               newRT(1) = 800+RT_curBlock(firstResponseIndex(2));
            else
                newRT(1) = 0; % no response on the first trial or the next 320ms
            end
        end

        for i = 2:lastTrial
            trialIndex = firstResponseIndex(i);
            if RT_curBlock(trialIndex)>RTCutOff(1) || (RT_curBlock(trialIndex)<RTCutOff(2) && RT_curBlock(trialIndex) > 0) % unambiguous ones
                if RT_curBlock(trialIndex)>RTCutOff(1) %560ms
                    newRT(i) = RT_curBlock(trialIndex);
                elseif RT_curBlock(trialIndex)<RTCutOff(2) % 320ms
                    if newRT(i-1) <= 0
                        newRT(i-1) = RT_curBlock(trialIndex)+800;
                    else
                    end
                end
            end
        end
        
        for i = 2:lastTrial
            trialIndex = firstResponseIndex(i);
            if RT_curBlock(trialIndex) <= RTCutOff(1) && RT_curBlock(trialIndex)>=RTCutOff(2) % ambiguous ones
                if newRT(i)==0 && newRT(i-1)~=0 && i > 1% one has no response
                    newRT(i) = RT_curBlock(trialIndex);
                end
                if newRT(i)~=0 && newRT(i-1)==0 
                    newRT(i-1) = RT_curBlock(trialIndex)+800; 
                end
                if newRT(i)==0 && newRT(i-1)==0 && i > 1 % neither has a response
                    if RT_curBlock(trialIndex) <= mean(RTCutOff) && imageCat(i-1) == press_condition
                        newRT(i-1) = RT_curBlock(trialIndex)+800;
                    elseif RT_curBlock(trialIndex) > mean(RTCutOff) && imageCat(i-1)== press_condition
                        newRT(i) = RT_curBlock(trialIndex);
                    end
                end
            end
        end 
    
    elseif onsetType == 4 % abrupt
         % first trial
        if RT_curBlock(1) > RTCutOff_abrupt(1) % first response
            newRT(1) = RT_curBlock(1);
        else  % no response during the 800ms, check the next response
            if RT_curBlock(2) > 0
                newRT(1) = RT_curBlock(2);
            elseif RT_curBlock(3) < RTCutOff_abrupt(2)
                newRT(1) = RT_curBlock(3)+800;
            else
                newRT(1) = 0;
            end
        end

        for i = 2:lastTrial           
            trialIndex = firstResponseIndex(i);
            if RT_curBlock(trialIndex) > RTCutOff_abrupt(1) % unambiguous ones
                    newRT(i) = RT_curBlock(trialIndex);
            else % no response
                    newRT(i) = 0; % no response
            end
        end        
    end
    
    for r = 1:numRepeatResponses
        trialIndex = repeatResponseIndex(r); % now deal with the multiple responses per trial
        expTrialNumber = subData_curBlock(trialIndex, 10); 
        if newRT(expTrialNumber) == 0 % no response was signed, assume the repeat response is this trial's
            newRT(expTrialNumber) = RT_curBlock(trialIndex);
        end
    end    
    
    if onsetType == 4 % 800~850 msec in the abrupt condition
        for c = 1:(length(newRT)-1)
            if newRT(c) == 0 % no response assigned
                if RT_curBlock(2*c+1) < RTCutOff_abrupt(2) && RT_curBlock(2*c+1) > 0
                    newRT(c) = RT_curBlock(2*c+1)+800;
                end
            end
        end
    end
    
    if onsetType == 4
        for k = 1:(length(newRT)-1)
            if newRT(k) == 0
                if RT_curBlock(2*k-1) <= 100 && RT_curBlock(2*k-1) >= 50
                    newRT(k) = RT_curBlock(2*k-1); 
                end
            end
        end
    end

    for i = 1:lastTrial
        if press_condition == 6 % press City task
            if newRT(i)== 0 % no response
                if imageCat(i) == 6 % city
                    press_count = press_count+1;
                    responseTypeN(i) = 20; % omission error (miss)
                    acc(i) = 0;
                    responseType{i} = 'OmissionError'; miss_count = miss_count+1;
                    imageCatStr{i} = 'city'; 
                else % mountain
                    nopress_count = nopress_count+1;
                    responseTypeN(i) = 10; % correctOmission (correct rejection)
                    acc(i) = 1;
                    responseType{i} = 'CorrectOmission';
                    imageCatStr{i} = 'mountain';
                end
            else
                if imageCat(i) == 6 % city
                    press_count = press_count+1;
                    responseTypeN(i) = 1; % hit
                    acc(i) = 1;
                    responseType{i} = 'CorrectCommission'; 
                    imageCatStr{i} = 'city';
                else
                    nopress_count = nopress_count+1;
                    responseTypeN(i) = 2; %falseAlarm
                    acc(i) = 0;
                    responseType{i} = 'CommissionError'; fa_count = fa_count+1;
                    imageCatStr{i} = 'mountain';
                end
            end  
        elseif press_condition == 16 % press Mountain task
            if newRT(i)== 0 % no response
                if imageCat(i) == 16 % moun
                    press_count = press_count+1;
                    responseTypeN(i) = 20; % omission error (miss)
                    acc(i) = 0;
                    responseType{i} = 'OmissionError'; miss_count = miss_count+1;
                    imageCatStr{i} = 'mountain';
                else % city
                    nopress_count = nopress_count+1;
                    responseTypeN(i) = 10; % correctOmission (correct rejection)
                    acc(i) = 1;
                    responseType{i} = 'CorrectOmission';
                    imageCatStr{i} = 'city';
                end
            else
                if imageCat(i) == 16 % mountain
                    press_count = press_count+1;
                    responseTypeN(i) = 1; % hit
                    acc(i) = 1;
                    responseType{i} = 'CorrectCommission';  
                    imageCatStr{i} = 'mountain';
                else
                    nopress_count = nopress_count+1;
                    responseTypeN(i) = 2; %falseAlarm
                    acc(i) = 0;
                    responseType{i} = 'CommissionError'; fa_count = fa_count+1;
                    imageCatStr{i} = 'city';
                end
            end  
        end
    end            

    press_totalnum = num2str(press_count); nopress_totalnum = num2str(nopress_count); 
    miss_num = num2str(miss_count); fa_num = num2str(fa_count);
    if press_count == 0
        press_count = 1;
    end
    if nopress_count == 0
        nopress_count = 1;
    end
    press_acc = round(100.*(1-(miss_count/press_count))); nopress_acc = round(100.*(1-(fa_count/nopress_count)));
    pressAcc = num2str(press_acc); nopressAcc = num2str(nopress_acc);
    %% Rest between blocks
    if b <= length(order)
        if b < length(order)
            Screen('FillRect', mainwin ,bgcolor);
            Screen('TextSize', mainwin, 36);
            Screen('DrawText', mainwin, ['You just completed block ' num2str(b) ' out of ' num2str(nblocks) ' blocks.'], left-100, center(2)-200, textcolor);
            Screen('DrawText', mainwin, ['In the last block, '], left-100, center(2)-140, textcolor);
            Screen('DrawText', mainwin, ['(1) you missed ' miss_num ' ' press ' scenes out of a total of ' press_totalnum ' scenes (the accuracy of ' pressAcc '%);'], left-100, center(2)-110, textcolor);
            Screen('DrawText', mainwin, ['(2) you made ' fa_num ' wrong responses to ' nopress ' scenes out of a total of ' nopress_totalnum ' scenes (the accuracy of ' nopressAcc '%).'], left-100, center(2)-80, textcolor);
            Screen('DrawText', mainwin, ['Please press the spacebar to start your break session.'], left-100, center(2), textcolor);
            Screen('Flip', mainwin);
            keyIsDown=0;
            while 1
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(spaceKey)
                        break ;
                    elseif keyCode(escKey)
                        ShowCursor;
                        fclose(outfile);
                        Screen('CloseAll');
                        return;
                    end
                end
            end
            WaitSecs(0.3);  
            
        elseif b == length(order)
            Screen('FillRect', mainwin ,bgcolor);
            Screen('TextSize', mainwin, 36);            
            Screen('DrawText', mainwin, ['You just completed block ' num2str(b) ' out of ' num2str(nblocks) ' blocks.'], left-100, center(2)-200, textcolor);
            Screen('DrawText', mainwin, ['In the last block, '], left-100, center(2)-140, textcolor);
            Screen('DrawText', mainwin, ['(1) you missed ' miss_num ' ' press ' scenes out of a total of ' press_totalnum ' scenes (the accuracy of ' pressAcc '%);'], left-100, center(2)-110, textcolor);
            Screen('DrawText', mainwin, ['(2) you made ' fa_num ' wrong responses to ' nopress ' scenes out of a total of ' nopress_totalnum ' scenes (the accuracy of ' nopressAcc '%).'], left-100, center(2)-80, textcolor);
            Screen('DrawText', mainwin, ['Please press the spacebar.'], left-100, center(2), textcolor);
            Screen('Flip', mainwin);
          
            keyIsDown=0;
            while 1
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(spaceKey)
                        break ;
                    elseif keyCode(escKey)
                        ShowCursor;
                        fclose(outfile);
                        Screen('CloseAll');
                        return;
                    end
                end
            end
            WaitSecs(0.3); 
        end
        % break time begins        
        if b < length(order)
            Breaktime(mainwin, breaktime);
            Screen('Flip', mainwin);       
            Screen('FillRect', mainwin ,bgcolor);
            Screen('TextSize', mainwin, 36);      
            Screen('DrawText', mainwin, ['Now you will begin the block # ' num2str(b+1) ' out of ' num2str(nblocks) ' blocks.' ], left, center(2),textcolor);  
            Screen('DrawText', mainwin, ['Please press the spacebar.'], left, center(2)+60, textcolor);
            Screen('Flip', mainwin);
            keyIsDown=0;
            while 1
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(spaceKey)
                        break ;
                    elseif keyCode(escKey)
                        ShowCursor;
                        fclose(outfile);
                        Screen('CloseAll');
                        return;
                    end
                end
            end
            WaitSecs(0.3);  
        end
        
        if b == length(order)
            Screen('FillRect', mainwin ,bgcolor);
            Screen('TextSize', mainwin, 36);
            Screen('DrawText', mainwin, ['Thank you for your participation.'], center(1)-350, center(2)-100, textcolor);
            Screen('DrawText', mainwin, ['Please get your experimenter.'], center(1)-350, center(2)-200,textcolor);
            Screen('Flip', mainwin);
            fclose(outfile);
            WaitSecs(5);        
        end
    end
    feedback_data_temp = [feedback_data_temp; feedback_data];
    feedback_data = [];
end

ShowCursor;
Screen('CloseAll');
