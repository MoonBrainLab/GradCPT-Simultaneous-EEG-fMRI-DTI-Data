#!/bin/bash
# Title: MRtrix DWI Preprocessing Script
# Description: This script preprocesses diffusion-weighted imaging (DWI) data using MRtrix3.
# It handles conversion, denoising, motion correction, bias correction, response function estimation,
# fiber orientation distribution (FOD) calculation, and tractography.
# Date: 2023.08.05, modified for GitHub sharing on 2025.09.01
# Dependencies: MRtrix3, FSL, ANTs (for bias correction), dcm2niix
# Usage: bash MRtrix_DWI_Preproc.sh <Raw_DWI> <RevPhaseImage> <AP_bvec> <AP_bval> <Anatomical>

# Function to display usage information
display_usage() {
    echo "Usage: $(basename $0) [Raw_DWI] [RevPhaseImage] [AP_bvec] [AP_bval] [Anatomical]"
    echo "This script preprocesses DWI data using MRtrix3. It requires 5 arguments:"
    echo "  1) Raw_DWI: The raw diffusion-weighted image (e.g., sub-002_acq-AP_dwi.nii.gz)"
    echo "  2) RevPhaseImage: The image acquired with reverse phase-encoding (e.g., sub-002_acq-PA_dwi.nii.gz)"
    echo "  3) AP_bvec: The bvec file for the AP direction (e.g., sub-002_acq-AP_dwi.bvec)"
    echo "  4) AP_bval: The bval file for the AP direction (e.g., sub-002_acq-AP_dwi.bval)"
    echo "  5) Anatomical: The anatomical image (e.g., sub-002_T1.nii)"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 5 ]; then
    display_usage
fi

# Assign input arguments to variables
RAW_DWI=$1
REV_PHASE=$2
AP_BVEC=$3
AP_BVAL=$4
ANAT=$5

# Check if input files exist
for file in "$RAW_DWI" "$REV_PHASE" "$AP_BVEC" "$AP_BVAL" "$ANAT"; do
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi
done

echo "Starting DWI preprocessing for $RAW_DWI..."

########################### STEP 1: Data Conversion and Denoising ###########################
# Convert DWI data to .mif format and perform denoising
mrconvert "$RAW_DWI" raw_dwi.mif -fslgrad "$AP_BVEC" "$AP_BVAL" -force
dwidenoise raw_dwi.mif dwi_den.mif -noise noise.mif -force

# Extract b0 images from AP direction
dwiextract dwi_den.mif - -bzero | mrmath - mean mean_b0_AP.mif -axis 3 -force

# Convert reverse phase (PA) image and extract b0 images
mrconvert "$REV_PHASE" PA.mif -force
mrconvert PA.mif - | mrmath - mean mean_b0_PA.mif -axis 3 -force

# Concatenate b0 images from AP and PA directions
mrcat mean_b0_AP.mif mean_b0_PA.mif -axis 3 b0_pair.mif -force

# Perform motion and distortion correction using dwifslpreproc
dwifslpreproc dwi_den.mif dwi_den_preproc.mif -nocleanup -pe_dir AP -rpe_pair -se_epi b0_pair.mif -eddy_options " --slm=linear --data_is_shelled" -force

# Perform bias field correction using ANTs
dwibiascorrect ants dwi_den_preproc.mif dwi_den_preproc_unbiased.mif -bias bias.mif -force

# Create a brain mask for subsequent processing
dwi2mask dwi_den_preproc_unbiased.mif mask.mif -force

########################### STEP 2: Response Function and FOD Estimation ###########################
# Estimate response functions for different tissue types
dwi2response dhollander dwi_den_preproc_unbiased.mif wm.txt gm.txt csf.txt -voxels voxels.mif -force

# Perform multi-shell multi-tissue constrained spherical deconvolution
dwi2fod msmt_csd dwi_den_preproc_unbiased.mif -mask mask.mif wm.txt wmfod.mif gm.txt gmfod.mif csf.txt csffod.mif -force

# Create a visualization of fiber orientation densities
mrconvert -coord 3 0 wmfod.mif - | mrcat csffod.mif gmfod.mif - vf.mif -force

# Normalize FODs for inter-subject comparison
mtnormalise wmfod.mif wmfod_norm.mif gmfod.mif gmfod_norm.mif csffod.mif csffod_norm.mif -mask mask.mif -force

########################### STEP 3: GM/WM Boundary Creation ###########################
# Convert anatomical image to .mif format
mrconvert "$ANAT" anat.mif -force

# Generate 5 tissue-type segmentation
5ttgen fsl anat.mif 5tt_nocoreg.mif -force

# Coregister anatomical to DWI data
dwiextract dwi_den_preproc_unbiased.mif - -bzero | mrmath - mean mean_b0_processed.mif -axis 3 -force
mrconvert mean_b0_processed.mif mean_b0_processed.nii.gz -force
mrconvert 5tt_nocoreg.mif 5tt_nocoreg.nii.gz -force
fslroi 5tt_nocoreg.nii.gz 5tt_vol0.nii.gz 0 1
flirt -in mean_b0_processed.nii.gz -ref 5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat diff2struct_fsl.mat
transformconvert diff2struct_fsl.mat mean_b0_processed.nii.gz 5tt_nocoreg.nii.gz flirt_import diff2struct_mrtrix.txt
mrtransform 5tt_nocoreg.mif -linear diff2struct_mrtrix.txt -inverse 5tt_coreg.mif -force

# Create GM/WM boundary seed region
5tt2gmwmi 5tt_coreg.mif gmwmSeed_coreg.mif -force

########################### STEP 4: Tractography ###########################
# Generate streamlines (10 million tracks)
tckgen -act 5tt_coreg.mif -backtrack -seed_gmwmi gmwmSeed_coreg.mif -nthreads 8 -maxlength 250 -cutoff 0.06 -select 10000000 wmfod.mif tracks_10M.tck -force

# Extract a subset of tracks for visualization
tckedit tracks_10M.tck -number 200k smallerTracks_200k.tck -force

# Optimize streamlines using SIFT2
tcksift2 -act 5tt_coreg.mif -out_mu sift_mu.txt -out_coeffs sift_coeffs.txt -nthreads 8 tracks_10M.tck wmfod.mif sift_1M.txt -force

echo "DWI preprocessing completed successfully!"
