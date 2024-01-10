#!/bin/bash

# Get inputs
T1_PATH=$1
T1_N3_PATH=$2
T1_NORM_PATH=$3

echo -------
echo INPUTS:
echo T1 path: $T1_PATH
echo T1 N3 path: $T1_N3_PATH
echo T1 normalized path: $T1_NORM_PATH

# Create temporary job directory
JOB_PATH=$(mktemp -d)
echo -------
echo Job directory path: $JOB_PATH

# Copy T1 to job directory
cp $T1_PATH $JOB_PATH/T1.nii.gz

# mri convert
echo -------
MRI_CONVERT_CMD="mri_convert $JOB_PATH/T1.nii.gz $JOB_PATH/T1.mgz"
echo $MRI_CONVERT_CMD
eval $MRI_CONVERT_CMD

# Do N3 correction
echo -------
N4_CMD="mri_nu_correct.mni --i $JOB_PATH/T1.mgz --o $JOB_PATH/T1_N3.mgz --n 2"
echo $N4_CMD
eval $N4_CMD

# mri convert
echo -------
MRI_CONVERT_CMD="mri_convert $JOB_PATH/T1_N3.mgz $T1_N3_PATH"
echo $MRI_CONVERT_CMD
eval $MRI_CONVERT_CMD

# Run freesurfers's mri normalize command
echo -------
MRI_NORMALIZE_CMD="mri_normalize -g 1 -mprage $JOB_PATH/T1_N3.mgz $JOB_PATH/T1_norm.mgz"
echo $MRI_NORMALIZE_CMD
eval $MRI_NORMALIZE_CMD

# mri convert
echo -------
MRI_CONVERT_CMD="mri_convert $JOB_PATH/T1_norm.mgz $T1_NORM_PATH"
echo $MRI_CONVERT_CMD
eval $MRI_CONVERT_CMD

# Delete job directory
echo -------
echo Removing job directory...
rm -rf $JOB_PATH
