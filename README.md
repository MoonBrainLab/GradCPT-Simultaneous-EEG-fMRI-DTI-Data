GradCPT-Simultaneous-EEG-fMRI-DTI Dataset Preprocessing Pipeline

This repository contains scripts for preprocessing EEG, fMRI, and DWI data. The pipeline includes EEG preprocessing with MATLAB, fMRI preprocessing with fMRIPrep, and DWI preprocessing with MRtrix3 and FSL. These scripts are designed to prepare raw neuroimaging data for downstream analysis, such as connectivity studies or statistical modeling.

Author: Younghwa Cha, Yeji Lee, Eunhee Ji, SoHyun Han, Sunhyun Min, Hyoungkyu Kim, Minseo Cho, Haesung Lee, Youngjai Park, Joon-Young Moon, Brain States and Transitions Lab, IBS, CNIR, Sungkyunkwan University

Table of Contents
Overview
Dependencies
Directory Structure
Preprocessing Scripts
EEG Preprocessing
fMRI Preprocessing
DWI Preprocessing

Overview
This pipeline processes:
EEG Data: Using a MATLAB script to preprocess EEG data and insert fMRI TR (repetition time) markers for concurrent EEG-fMRI studies.
fMRI Data: Using fMRIPrep via a Bash script for preprocessing functional MRI data.
DWI Data: Using MRtrix3 and FSL scripts, along with MATLAB scripts, for diffusion-weighted imaging preprocessing and structural connectivity analysis.

Dependencies
Ensure the following software is installed:
MATLAB: For EEG preprocessing (fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m) and DWI ROI extraction/plotting (extractROIs.m, plotSeedConnResults.m, saveniidat.m).
Required MATLAB toolboxes: EEGLAB (for EEG preprocessing).
fMRIPrep: For fMRI preprocessing (run_fmriprep.sh). Install via Docker or Singularity.
MRtrix3: For DWI preprocessing (MRtrix_DWI_Preproc.sh).
FSL: For DWI preprocessing and connectivity analysis (Structural_Connectivity.sh, extractROIs.m, plotSeedConnResults.m).
FreeSurfer: For anatomical segmentation in DWI connectivity analysis.
ANTs: For bias correction in DWI preprocessing.
dcm2niix: For converting DICOM to NIfTI (if needed).

Installation instructions:
MATLAB
EEGLAB
fMRIPrep
MRtrix3
FSL
FreeSurfer
ANTs
dcm2niix

Neuroimaging Preprocessing Pipeline
This repository contains scripts for preprocessing EEG, fMRI, and DWI data, developed for neuroimaging studies. The pipeline includes EEG preprocessing with MATLAB, fMRI preprocessing with fMRIPrep, and DWI preprocessing with MRtrix3 and FSL. These scripts are designed to prepare raw neuroimaging data for downstream analysis, such as connectivity studies or statistical modeling.
Author: Yeji Lee, Brain States and Transitions Lab, IBS, CNIR, Sungkyunkwan UniversityDate: 2025.09.01
Table of Contents

Overview
Dependencies
Directory Structure
Preprocessing Scripts
EEG Preprocessing
fMRI Preprocessing
DWI Preprocessing


Usage
Outputs
Notes
License

Overview
This pipeline processes:

EEG Data: Using a MATLAB script to preprocess EEG data and insert fMRI TR (repetition time) markers for concurrent EEG-fMRI studies.
fMRI Data: Using fMRIPrep via a Bash script for preprocessing functional MRI data.
DWI Data: Using MRtrix3 and FSL scripts, along with MATLAB scripts, for diffusion-weighted imaging preprocessing and structural connectivity analysis.

Dependencies
Ensure the following software is installed:

MATLAB: For EEG preprocessing (fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m) and DWI ROI extraction/plotting (extractROIs.m, plotSeedConnResults.m, saveniidat.m).
Required MATLAB toolboxes: EEGLAB (for EEG preprocessing).


fMRIPrep: For fMRI preprocessing (run_fmriprep.sh). Install via Docker or Singularity.
MRtrix3: For DWI preprocessing (MRtrix_DWI_Preproc.sh).
FSL: For DWI preprocessing and connectivity analysis (Structural_Connectivity.sh, extractROIs.m, plotSeedConnResults.m).
FreeSurfer: For anatomical segmentation in DWI connectivity analysis.
ANTs: For bias correction in DWI preprocessing.
dcm2niix: For converting DICOM to NIfTI (if needed).

Installation instructions:

MATLAB
EEGLAB
fMRIPrep
MRtrix3
FSL
FreeSurfer
ANTs
dcm2niix

Directory Structure
The expected directory structure for each subject is:
data_dir/
├── sub-XXX/
│   ├── eeg/
│   │   ├── sub-XXX_eeg.edf  # Raw EEG data
│   │   ├── sub-XXX_tr.txt   # fMRI TR timings
│   ├── func/
│   │   ├── sub-XXX_task-rest_bold.nii.gz  # Raw fMRI data
│   ├── anat/
│   │   ├── sub-XXX_T1w.nii.gz  # T1-weighted image
│   ├── dwi/
│   │   ├── sub-XXX_acq-AP_dwi.nii.gz
│   │   ├── sub-XXX_acq-AP_dwi.bval
│   │   ├── sub-XXX_acq-AP_dwi.bvec
│   │   ├── sub-XXX_acq-PA_dwi.nii.gz
│   │   ├── sub-XXX_eddy_corrected.nii.gz  # Preprocessed DWI
│   │   ├── sub-XXX_unwarped_b0.nii.gz    # Unwarped b0
│   │   ├── sub-XXX_brain_mask.nii.gz      # Brain mask
│   ├── derivatives/
│   │   ├── fmriprep/  # fMRIPrep outputs
│   │   ├── eeg/       # EEG preprocessing outputs
│   │   ├── connectome_sub-XXX/  # DWI connectivity outputs
├── scripts/
│   ├── fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m
│   ├── run_fmriprep.sh
│   ├── MRtrix_DWI_Preproc.sh
│   ├── Structural_Connectivity.sh
│   ├── extractROIs.m
│   ├── plotSeedConnResults.m
│   ├── saveniidat.m

Preprocessing Scripts
EEG Preprocessing

Script: fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m
Purpose: Preprocesses EEG data (e.g., filtering, artifact removal) and inserts fMRI TR markers for concurrent EEG-fMRI studies using EEGLAB.
Input:
Raw EEG data (e.g., sub-XXX_eeg.edf)
fMRI TR timing file (e.g., sub-XXX_tr.txt)


Output:
Preprocessed EEG data with TR markers (saved in data_dir/sub-XXX/eeg/derivatives/)


Usage:% In MATLAB
cd data_dir/sub-XXX/eeg
fMRIb_preprocessing_EEG_fMRI_data_insert_TR('sub-XXX_eeg.edf', 'sub-XXX_tr.txt')


Notes:
Ensure EEGLAB is installed and added to the MATLAB path.
The script assumes the EEG data is in EDF format and TR timings are in a text file.



fMRI Preprocessing

Script: run_fmriprep.sh
Purpose: Runs fMRIPrep to preprocess fMRI data, including motion correction, slice-timing correction, and registration to anatomical space.
Input:
T1-weighted image (e.g., sub-XXX_T1w.nii.gz)
Functional MRI data (e.g., sub-XXX_task-rest_bold.nii.gz)


Output:
Preprocessed fMRI data in data_dir/derivatives/fmriprep/


Usage:bash scripts/run_fmriprep.sh /path/to/data_dir /path/to/output_dir sub-XXX


Notes:
Requires Docker or Singularity for fMRIPrep.
Ensure BIDS-compliant data structure (see BIDS specification).
Adjust fMRIPrep options (e.g., --fs-license-file) as needed.



DWI Preprocessing

Scripts:
MRtrix_DWI_Preproc.sh: Preprocesses DWI data (denoising, motion/distortion correction, FOD estimation).
Structural_Connectivity.sh: Generates structural connectivity matrices using bedpostx and probtrackx2.
extractROIs.m: Extracts ROIs from the Desikan-Killiany atlas.
plotSeedConnResults.m: Plots connectivity matrices from probtrackx2 outputs.
saveniidat.m: Saves data in NIfTI format (used by extractROIs.m or plotSeedConnResults.m).


Purpose:
MRtrix_DWI_Preproc.sh: Prepares DWI data for tractography.
Structural_Connectivity.sh: Performs anatomical segmentation, registration, and probabilistic tractography.
MATLAB scripts: Handle ROI extraction and connectivity visualization.


Input:
T1-weighted image (e.g., sub-XXX_T1w.nii.gz)
DWI images (e.g., sub-XXX_acq-AP_dwi.nii.gz, sub-XXX_acq-PA_dwi.nii.gz)
bval/bvec files (e.g., sub-XXX_acq-AP_dwi.bval, sub-XXX_acq-AP_dwi.bvec)
Preprocessed DWI files (e.g., sub-XXX_eddy_corrected.nii.gz, sub-XXX_unwarped_b0.nii.gz, sub-XXX_brain_mask.nii.gz)


Output:
Preprocessed DWI data (e.g., data_dir/sub-XXX/dwi/*.mif)
Connectivity matrices (e.g., data_dir/sub-XXX/connectome_sub-XXX/SeedConnResults/seed2all_roi*.txt)
ROI files (e.g., data_dir/sub-XXX/connectome_sub-XXX/subject_bedpostx/rois/roi*.nii)


Usage:# DWI preprocessing
bash scripts/MRtrix_DWI_Preproc.sh sub-XXX_acq-AP_dwi.nii.gz sub-XXX_acq-PA_dwi.nii.gz sub-XXX_acq-AP_dwi.bvec sub-XXX_acq-AP_dwi.bval sub-XXX_T1w.nii.gz
# Structural connectivity
bash scripts/Structural_Connectivity.sh sub-XXX /path/to/data_dir sub-XXX_T1w.nii.gz sub-XXX_acq-AP_dwi.nii.gz sub-XXX_acq-AP_dwi.bval sub-XXX_acq-AP_dwi.bvec sub-XXX_eddy_corrected.nii.gz sub-XXX_unwarped_b0.nii.gz sub-XXX_brain_mask.nii.gz
# MATLAB scripts (run in respective directories)
matlab -nodesktop -nosplash -r "extractROIs; quit"
matlab -nodesktop -nosplash -r "plotSeedConnResults; quit"


Notes:
Run MRtrix_DWI_Preproc.sh before Structural_Connectivity.sh to generate preprocessed DWI files.
extractROIs.m generates 108 ROIs based on the Desikan-Killiany atlas.
saveniidat.m is assumed to be a utility script for saving NIfTI files; ensure it is compatible with your MATLAB environment.



Usage

Set up the environment:

Install all dependencies and add them to your system path.
For MATLAB, add EEGLAB to the path: addpath('/path/to/eeglab').
For fMRIPrep, provide a FreeSurfer license file (--fs-license-file).


Organize data:

Place raw data in a BIDS-compliant structure under data_dir/sub-XXX/.
Ensure preprocessed DWI files are available for Structural_Connectivity.sh.


Run scripts:

EEG: Run fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m in MATLAB.
fMRI: Run run_fmriprep.sh in a terminal with Docker/Singularity.
DWI: Run MRtrix_DWI_Preproc.sh followed by Structural_Connectivity.sh, then execute MATLAB scripts in their respective directories.


Batch processing:

Create a loop script to process multiple subjects, e.g.:for sub in sub-001 sub-002; do
  bash scripts/run_fmriprep.sh /path/to/data_dir /path/to/output_dir $sub
  matlab -nodesktop -nosplash -r "cd data_dir/$sub/eeg; fMRIb_preprocessing_EEG_fMRI_data_insert_TR('$sub_eeg.edf', '$sub_tr.txt'); quit"
  bash scripts/MRtrix_DWI_Preproc.sh $sub_acq-AP_dwi.nii.gz $sub_acq-PA_dwi.nii.gz $sub_acq-AP_dwi.bvec $sub_acq-AP_dwi.bval $sub_T1w.nii.gz
  bash scripts/Structural_Connectivity.sh $sub /path/to/data_dir $sub_T1w.nii.gz $sub_acq-AP_dwi.nii.gz $sub_acq-AP_dwi.bval $sub_acq-AP_dwi.bvec $sub_eddy_corrected.nii.gz $sub_unwarped_b0.nii.gz $sub_brain_mask.nii.gz
done





Outputs

EEG:
Preprocessed EEG data with TR markers in data_dir/sub-XXX/eeg/derivatives/.


fMRI:
Preprocessed fMRI data in data_dir/derivatives/fmriprep/, including motion-corrected BOLD images and confounds.


DWI:
Preprocessed DWI files (e.g., .mif, brain mask) in data_dir/sub-XXX/dwi/.
Connectivity matrices and ROI files in data_dir/sub-XXX/connectome_sub-XXX/.



Notes

BIDS Compliance: fMRI preprocessing requires a BIDS-compliant dataset. Use tools like bids-validator to verify.
MATLAB Scripts: fMRIb_preprocessing_EEG_fMRI_data_insert_TR.m, extractROIs.m, plotSeedConnResults.m, and saveniidat.m are assumed to be provided. If not, users must implement them based on the expected functionality (e.g., EEG filtering, ROI extraction for 108 regions, connectivity plotting).
DWI Preprocessing: MRtrix_DWI_Preproc.sh must be run before Structural_Connectivity.sh to generate required inputs (eddy_corrected.nii.gz, unwarped_b0.nii.gz, brain_mask.nii.gz).
Performance: Some steps (e.g., bedpostx, recon-all) are computationally intensive. Ensure sufficient CPU/GPU resources and disk space.
Customization: Adjust the number of ROIs (default: 108) in Structural_Connectivity.sh if using a different atlas.

License
This project is licensed under the MIT License. See the LICENSE file for details.
