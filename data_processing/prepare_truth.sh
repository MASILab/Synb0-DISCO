#!/bin/bash

# Get inputs
B0_U_PATH=$1
T1_PATH=$2
T1_ATLAS_PATH=$3
T1_ATLAS_2_5_PATH=$4
T1_MASK_PATH=$5
ANTS_AFFINE_PATH=$6
ANTS_WARP_PATH=$7
RESULTS_PATH=$8

echo -------
echo INPUTS:
echo Undistorted b0 path: $B0_U_PATH
echo T1 path: $T1_PATH
echo T1 atlas path: $T1_ATLAS_PATH
echo T1 2.5 iso atlas path: $T1_ATLAS_2_5_PATH
echo T1 mask path: $T1_MASK_PATH
echo ANTS affine path: $ANTS_AFFINE_PATH
echo ANTS warp path: $ANTS_WARP_PATH
echo Results path: $RESULTS_PATH

# Create temporary job directory
JOB_PATH=$(mktemp -d)
echo -------
echo Job directory path: $JOB_PATH

# Make results directory
echo -------
echo Making results directory...
mkdir -p $RESULTS_PATH

# epi_reg undistorted b0 to T1; should be nice since B0 is undistorted
echo -------
echo epi_reg undistorted b0 to T1
EPI_REG_U_PATH=$JOB_PATH/epi_reg_u
EPI_REG_U_MAT_PATH=$JOB_PATH/epi_reg_u.mat
EPI_REG_CMD="epi_reg --epi=$B0_U_PATH --t1=$T1_PATH --t1brain=$T1_MASK_PATH --out=$EPI_REG_U_PATH"
echo $EPI_REG_CMD
eval $EPI_REG_CMD

# Convert FSL transform to ANTS transform
echo -------
echo converting FSL transform to ANTS transform
EPI_REG_U_ANTS_PATH=$JOB_PATH/epi_reg_u_ANTS.txt
C3D_CMD="c3d_affine_tool -ref $T1_PATH -src $B0_U_PATH $EPI_REG_U_MAT_PATH -fsl2ras -oitk $EPI_REG_U_ANTS_PATH"
echo $C3D_CMD
eval $C3D_CMD

# Apply linear transform to undistorted b0 to get it into atlas space
echo -------
echo Apply linear transform to undistorted b0
B0_U_LIN_ATLAS_2_5_PATH=$JOB_PATH/b0_u_lin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $B0_U_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t $ANTS_AFFINE_PATH -t $EPI_REG_U_ANTS_PATH -o $B0_U_LIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Apply nonlinear transform to undistorted b0 to get it into atlas space
echo -------
echo Apply nonlinear transform to undistorted b0
B0_U_NONLIN_ATLAS_2_5_PATH=$JOB_PATH/b0_u_nonlin_atlas_2_5.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $B0_U_PATH -r $T1_ATLAS_2_5_PATH -n BSpline -t $ANTS_WARP_PATH -t $ANTS_AFFINE_PATH -t $EPI_REG_U_ANTS_PATH -o $B0_U_NONLIN_ATLAS_2_5_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD

# Copy what you want to results path
echo -------
echo Copying results to results path...
cp $EPI_REG_U_MAT_PATH $RESULTS_PATH
cp $EPI_REG_U_ANTS_PATH $RESULTS_PATH
cp $B0_U_LIN_ATLAS_2_5_PATH $RESULTS_PATH
cp $B0_U_NONLIN_ATLAS_2_5_PATH $RESULTS_PATH

# Delete job directory
echo -------
echo Removing job directory...
rm -rf $JOB_PATH
