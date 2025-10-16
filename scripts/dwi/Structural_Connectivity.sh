#!/bin/bash
# Title: Structural Connectivity Processing Script
# Description: This script processes diffusion-weighted imaging (DWI) data to generate structural connectivity matrices
# using FreeSurfer, FSL, and MATLAB. It performs anatomical segmentation, DWI registration, tractography with bedpostx,
# and probabilistic tractography with probtrackx2.
# Dependencies: FreeSurfer, FSL (including bedpostx_gpu or bedpostx), MATLAB, dcm2niix
# Usage: bash Structural_Connectivity.sh <subject_id> <data_dir> <t1_image> <dwi_image> <bval_file> <bvec_file> <eddy_corrected_dwi> <b0_unwarped> <brain_mask>
# Example: bash Structural_Connectivity.sh sub-001 /path/to/data sub-001_T1w.nii.gz sub-001_acq-AP_dwi.nii.gz sub-001_acq-AP_dwi.bval sub-001_acq-AP_dwi.bvec sub-001_eddy_corrected.nii.gz unwarped_b0.nii.gz brain_mask.nii.gz

# Function to display usage information
display_usage() {
    echo "Usage: $(basename $0) [subject_id] [data_dir] [t1_image] [dwi_image] [bval_file] [bvec_file] [eddy_corrected_dwi] [b0_unwarped] [brain_mask]"
    echo "This script processes structural connectivity using FreeSurfer, FSL, and MATLAB. It requires 9 arguments:"
    echo "  1) subject_id: Subject identifier (e.g., sub-001)"
    echo "  2) data_dir: Directory containing subject data"
    echo "  3) t1_image: T1-weighted anatomical image (e.g., sub-001_T1w.nii.gz)"
    echo "  4) dwi_image: Raw DWI image (e.g., sub-001_acq-AP_dwi.nii.gz)"
    echo "  5) bval_file: bval file for DWI (e.g., sub-001_acq-AP_dwi.bval)"
    echo "  6) bvec_file: bvec file for DWI (e.g., sub-001_acq-AP_dwi.bvec)"
    echo "  7) eddy_corrected_dwi: Eddy-corrected DWI image (e.g., sub-001_eddy_corrected.nii.gz)"
    echo "  8) b0_unwarped: Unwarped b0 image (e.g., unwarped_b0.nii.gz)"
    echo "  9) brain_mask: Brain mask image (e.g., brain_mask.nii.gz)"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 9 ]; then
    display_usage
fi

# Assign input arguments to variables
SUBJECT_ID=$1
DATA_DIR=$2
T1=$3
DWI=$4
BVAL=$5
BVEC=$6
EDDY_CORRECTED=$7
B0_UNWARPED=$8
BRAIN_MASK=$9

# Check if input files exist
for file in "$T1" "$DWI" "$BVAL" "$BVEC" "$EDDY_CORRECTED" "$B0_UNWARPED" "$BRAIN_MASK"; do
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi
done

echo "Starting structural connectivity processing for $SUBJECT_ID at $(date)..."

# Define output directories
SUBJECT_DIR="${DATA_DIR}/${SUBJECT_ID}"
SUBJECT_DIR2="${SUBJECT_DIR}/dwi/${SUBJECT_ID}_processed"
OUT_DIR="${SUBJECT_DIR2}/connectomes/subject_bedpostx"
OUT_DIR2="${SUBJECT_DIR2}/connectomes"
mkdir -p "$OUT_DIR" "$OUT_DIR2/SeedConnResults"

# Change to data directory
cd "$DATA_DIR" || { echo "Error: Cannot access $DATA_DIR"; exit 1; }

########################### STEP 1: Anatomical Processing with FreeSurfer ###########################
# Run FreeSurfer recon-all for anatomical segmentation
recon-all -i "$T1" -subjid "$SUBJECT_ID" -all -sd "$SUBJECT_DIR"

# Convert FreeSurfer segmentation to T1 space (Desikan-Killiany atlas)
echo "Desikan-Killiany atlas labeling..."
mri_label2vol \
    --seg "${SUBJECT_DIR}/anat/${SUBJECT_ID}_aparc+aseg.mgz" \
    --temp "${SUBJECT_DIR}/anat/${SUBJECT_ID}_rawavg.mgz" \
    --o "${SUBJECT_DIR}/anat/${SUBJECT_ID}_aparc+aseg_T1space.nii.gz" \
    --regheader "${SUBJECT_DIR}/anat/${SUBJECT_ID}_aparc+aseg.mgz"

########################### STEP 2: DWI Registration ###########################
# Extract b0 image for registration
echo "Extracting b0 image for registration..."
fslroi "$B0_UNWARPED" "${SUBJECT_DIR2}/b0_img.nii.gz" 0 1

# Register atlas to DWI space
echo "Registering atlas to DWI space..."
flirt -in "${SUBJECT_DIR}/anat/${SUBJECT_ID}_aparc+aseg_T1space.nii.gz" \
      -ref "${SUBJECT_DIR2}/b0_img.nii.gz" \
      -applyxfm -usesqform \
      -interp nearestneighbour \
      -out "${SUBJECT_DIR2}/atlas_LUT.nii.gz"

########################### STEP 3: Prepare Files for BedpostX ###########################
# Copy necessary files to bedpostx directory
echo "Preparing files for bedpostx..."
ATLAS_ROI="${SUBJECT_DIR2}/atlas_LUT.nii.gz"
cp "$BVAL" "${OUT_DIR}/bvals"
cp "$BVEC" "${OUT_DIR}/bvecs"
cp "$EDDY_CORRECTED" "${OUT_DIR}/data.nii.gz"
cp "$BRAIN_MASK" "${OUT_DIR}/nodif_brain_mask.nii.gz"
cp "$ATLAS_ROI" "$OUT_DIR"

########################### STEP 4: Run BedpostX ###########################
# Run bedpostx (try GPU version first, fall back to CPU if needed)
echo "Running bedpostx..."
if ! bedpostx_gpu "$OUT_DIR"; then
    echo "bedpostx_gpu failed, trying bedpostx..."
    bedpostx "$OUT_DIR"
fi

########################### STEP 5: Extract ROIs with MATLAB ###########################
# Copy and run MATLAB script for ROI extraction
echo "Extracting ROIs with MATLAB..."
if [ ! -f "extractROIs.m" ]; then
    echo "Error: extractROIs.m not found in $DATA_DIR"
    exit 1
fi
cp extractROIs.m "$OUT_DIR"
cd "$OUT_DIR" || { echo "Error: Cannot access $OUT_DIR"; exit 1; }
matlab -nodesktop -nosplash -r "extractROIs; quit"

########################### STEP 6: Probabilistic Tractography with ProbtrackX2 ###########################
# Create list of ROI files
echo "Preparing ROI list for probtrackx2..."
SEG_DIR="${OUT_DIR}/rois"
cd "$DATA_DIR" || { echo "Error: Cannot access $DATA_DIR"; exit 1; }
> roinames.txt
for i in $(seq 1 108); do
    echo "${SEG_DIR}/roi${i}.nii" >> roinames.txt
done

# Run probtrackx2 for each seed ROI
echo "Running probtrackx2 for structural connectivity..."
for seed in $(seq 1 108); do
    probtrackx2_gpu \
        -s "${OUT_DIR2}/subject_bedpostx.bedpostX/merged" \
        -m "${OUT_DIR2}/subject_bedpostx.bedpostX/nodif_brain_mask.nii.gz" \
        --dir=tmp \
        -x "${SEG_DIR}/roi${seed}.nii" \
        --targetmasks="${DATA_DIR}/roinames.txt" \
        --ompl \
        --os2t \
        --s2tastext
    mv -f tmp/matrix_seeds_to_all_targets "${OUT_DIR2}/SeedConnResults/seed2all_roi${seed}.txt"
    mv -f tmp/matrix_seeds_to_all_targets_lengths "${OUT_DIR2}/SeedConnResults/seed2all_length_roi${seed}.txt"
    rm -r tmp
done

########################### STEP 7: Plot Connectivity Results with MATLAB ###########################
# Copy and run MATLAB script for plotting results
echo "Plotting connectivity results with MATLAB..."
if [ ! -f "plotSeedConnResults.m" ]; then
    echo "Error: plotSeedConnResults.m not found in $DATA_DIR"
    exit 1
fi
cp plotSeedConnResults.m "${OUT_DIR2}/SeedConnResults"
cd "${OUT_DIR2}/SeedConnResults" || { echo "Error: Cannot access ${OUT_DIR2}/SeedConnResults"; exit 1; }
matlab -nodesktop -nosplash -r "plotSeedConnResults; quit"

echo "Structural connectivity processing completed successfully at $(date)!"
