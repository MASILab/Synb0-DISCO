#!/bin/bash

# Get path
export ROOT_DIR=/Users/elianaphillips/Desktop/NCIRE/SynB0-DISCO/

# Get inputs
B0_D_PATH=$1
T1_PATH=$2
T1_ATLAS_PATH=$3
T1_ATLAS_2_5_PATH=$4
RESULTS_PATH=$5

echo -------
echo INPUTS:
echo Distorted b0 path: $B0_D_PATH
echo T1 path: $T1_PATH
echo T1 atlas path: $T1_ATLAS_PATH
echo T1 2.5 iso atlas path: $T1_ATLAS_2_5_PATH
echo Results path: $RESULTS_PATH

# Create temporary job directory
JOB_PATH=$(mktemp -d)
echo -------
echo Job directory path: $JOB_PATH

# Make results directory
echo -------
echo Making results directory...
mkdir -p $RESULTS_PATH

# Normalize T1
echo -------
echo Normalizing T1
T1_N3_PATH=$JOB_PATH/T1_N3.nii.gz
T1_NORM_PATH=$JOB_PATH/T1_norm.nii.gz
NORM_SCRPT=$ROOT_DIR/data_processing/normalize_T1.sh
NORMALIZE_CMD="$NORM_SCRPT $T1_PATH $T1_N3_PATH $T1_NORM_PATH"
echo $NORMALIZE_CMD
eval $NORMALIZE_CMD

# If 1mm T1 atlas is stripped (aka input T1 is stripped), copy input T1 over as T1_stripped
# Otherwise, extract brain from input T1
#
# This step exists because epi_reg requires an extracted brain. It uses the name of the atlas to
# track stripped status--not a super elegant solution
echo -------
T1_MASK_PATH=$JOB_PATH/T1_mask.nii.gz
if [[ "$T1_ATLAS_PATH" == *"mask"* ]]; then 
  echo Copying user provided T1 Mask
  cp $T1_PATH $T1_MASK_PATH
else
  echo Skull stripping T1
  BET_CMD="bet $T1_PATH $T1_MASK_PATH -R"
  echo $BET_CMD
  eval $BET_CMD
fi

# epi_reg distorted b0 to T1; wont be perfect since B0 is distorted
echo -------
echo epi_reg distorted b0 to T1
EPI_REG_D_PATH=$JOB_PATH/epi_reg_d
EPI_REG_D_MAT_PATH=$JOB_PATH/epi_reg_d.mat
EPI_REG_CMD="epi_reg --epi=$B0_D_PATH --t1=$T1_PATH --t1brain=$T1_MASK_PATH --out=$EPI_REG_D_PATH"
echo $EPI_REG_CMD
eval $EPI_REG_CMD

# Convert FSL transform to ANTS transform
echo -------
echo converting FSL transform to ANTS transform
EPI_REG_D_ANTS_PATH=$JOB_PATH/epi_reg_d_ANTS.txt
C3D_TOOL_PATH=/Applications/C3D/bin/c3d_affine_tool
C3D_CMD="$C3D_TOOL_PATH -ref $T1_PATH -src $B0_D_PATH $EPI_REG_D_MAT_PATH -fsl2ras -oitk $EPI_REG_D_ANTS_PATH"
echo $C3D_CMD
eval $C3D_CMD

# ANTs register T1 to atlas (both must either be full T1s or stripped T1s)
echo -------
echo ANTS syn registration
ANTS_OUT=$JOB_PATH/ANTS
ANTS_CMD="antsRegistrationSyNQuick.sh -d 3 -f $T1_ATLAS_PATH -m $T1_PATH -o $ANTS_OUT"
echo $ANTS_CMD
eval $ANTS_CMD

# Apply linear transform to normalized T1 to get it into atlas space
echo -------
echo Apply linear transform to T1
T1_NORM_LIN_ATLAS_2_5_PATH=$JOB_PATH/T1_norm_lin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $T1_NORM_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t "$ANTS_OUT"0GenericAffine.mat -o $T1_NORM_LIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Apply linear transform to distorted b0 to get it into atlas space
echo -------
echo Apply linear transform to distorted b0
B0_D_LIN_ATLAS_2_5_PATH=$JOB_PATH/b0_d_lin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $B0_D_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t "$ANTS_OUT"0GenericAffine.mat -t $EPI_REG_D_ANTS_PATH -o $B0_D_LIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Apply nonlinear transform to normalized T1 to get it into atlas space
echo -------
echo Apply nonlinear transform to T1
T1_NORM_NONLIN_ATLAS_2_5_PATH=$JOB_PATH/T1_norm_nonlin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $T1_NORM_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t "$ANTS_OUT"1Warp.nii.gz -t "$ANTS_OUT"0GenericAffine.mat -o $T1_NORM_NONLIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Apply nonlinear transform to distorted b0 to get it into atlas space
echo -------
echo Apply nonlinear transform to distorted b0
B0_D_NONLIN_ATLAS_2_5_PATH=$JOB_PATH/b0_d_nonlin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $B0_D_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t "$ANTS_OUT"1Warp.nii.gz -t "$ANTS_OUT"0GenericAffine.mat -t $EPI_REG_D_ANTS_PATH -o $B0_D_NONLIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Copy what you want to results path
echo -------
echo Copying results to results path...
cp $T1_NORM_PATH $RESULTS_PATH
cp $T1_MASK_PATH $RESULTS_PATH
cp $EPI_REG_D_MAT_PATH $RESULTS_PATH
cp $EPI_REG_D_ANTS_PATH $RESULTS_PATH
cp "$ANTS_OUT"0GenericAffine.mat $RESULTS_PATH
cp "$ANTS_OUT"1Warp.nii.gz $RESULTS_PATH
cp "$ANTS_OUT"1InverseWarp.nii.gz $RESULTS_PATH
cp $T1_NORM_LIN_ATLAS_2_5_PATH $RESULTS_PATH
cp $T1_NORM_NONLIN_ATLAS_2_5_PATH $RESULTS_PATH
cp $B0_D_LIN_ATLAS_2_5_PATH $RESULTS_PATH
cp $B0_D_NONLIN_ATLAS_2_5_PATH $RESULTS_PATH

# Delete job directory
echo -------
echo Removing job directory...
rm -rf $JOB_PATH
