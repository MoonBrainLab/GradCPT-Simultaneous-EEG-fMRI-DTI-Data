#!/bin/bash

# Example: bash run_fmriprep.sh sub-001

# ========== CONFIG ==========
BIDS_DIR="./bids"  # BIDS-formatted dataset root
DERIV_DIR="./bids/derivatives"
IMG="./code/fmriprep-23.0.1.simg"
LICENSE="./code/license.txt"
SUBJECT=$1  # Participant label (e.g., sub-001)

# Check if subject was provided
if [ -z "$SUBJECT" ]; then
  echo "Usage: bash run_fmriprep.sh <participant-label (e.g., sub-001)>"
  exit 1
fi

# ========== RUN fMRIPrep ==========
singularity run --cleanenv \
  -B "${PWD}" \
  ${IMG} \
  ${BIDS_DIR} ${DERIV_DIR} participant \
  --participant-label ${SUBJECT} \
  --fs-license-file ${LICENSE} \
  --stop-on-first-crash \
  --skip_bids_validation
