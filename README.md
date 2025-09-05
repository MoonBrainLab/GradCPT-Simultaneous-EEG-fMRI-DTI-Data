# GradCPT-Simultaneous-EEG-fMRI-DTI Dataset Preprocessing Pipeline

This repository contains the custom code developed by Jihyang Jun and Vanessa G. Lee for presenting gradCPT stimuli in the gradCPT task.
This repository also contains scripts for preprocessing EEG, fMRI, and DWI data. The pipeline includes EEG preprocessing with MATLAB, fMRI preprocessing with fMRIPrep, and DWI preprocessing with MRtrix3 and FSL.

Author: Younghwa Cha, Yeji Lee, Eunhee Ji, SoHyun Han, Sunhyun Min, Hyoungkyu Kim, Minseo Cho, Haesung Lee, Youngjai Park, Joon-Young Moon, Brain States and Transitions Lab, IBS, CNIR, Sungkyunkwan University

# Overview
# This pipeline processes:
gradCPT task: Using a MATLAB script to present gradCPT stimuli (CPT_withinSubject1_v2.m)

EEG Data: Using a MATLAB script to preprocess EEG data and insert fMRI TR (repetition time) markers for concurrent EEG-fMRI studies.

fMRI Data: Using fMRIPrep via a Bash script for preprocessing functional MRI data.

DWI Data: Using MRtrix3 and FSL scripts, along with MATLAB scripts, for diffusion-weighted imaging preprocessing and structural connectivity analysis.

# Dependencies
Ensure the following software is installed:

MATLAB: For EEG preprocessing (fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m) and DWI ROI extraction/plotting (extractROIs.m, plotSeedConnResults.m, saveniidat.m).

Required MATLAB toolboxes: EEGLAB (for EEG preprocessing).

fMRIPrep: For fMRI preprocessing (run_fmriprep.sh). Install via Docker or Singularity.

MRtrix3: For DWI preprocessing (MRtrix_DWI_Preproc.sh).

FSL: For DWI processing and connectivity analysis (Structural_Connectivity.sh, extractROIs.m, plotSeedConnResults.m).

FreeSurfer: For anatomical segmentation in DWI connectivity analysis.

ANTs: For bias correction in DWI preprocessing.

dcm2niix: For converting DICOM to NIfTI (if needed).

# Installation instructions:
MATLAB

EEGLAB

fMRIPrep

MRtrix3

FSL

FreeSurfer

ANTs

dcm2niix
