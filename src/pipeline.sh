#!/bin/bash

TOPUP=1
MNI_T1_1_MM_FILE=/extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

for arg in "$@"
do
    case $arg in
        -i|--notopup)
            TOPUP=0
	        ;;
    	-s|--stripped)
	        MNI_T1_1_MM_FILE=/extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz
            ;;
    esac
done

# Set path for executable
export PATH=$PATH:/extra

# Set up freesurfer
export FREESURFER_HOME=/extra/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Set up FSL
. /extra/fsl/etc/fslconf/fsl.sh
export PATH=$PATH:/extra/fsl/bin
export FSLDIR=/extra/fsl

# Set up ANTS
export ANTSPATH=/extra/ANTS/bin/ants/bin/
export PATH=$PATH:$ANTSPATH:/extra/ANTS/ANTs/Scripts

# Set up pytorch
source /extra/pytorch/bin/activate

# Prepare input
/extra/prepare_input.sh /INPUTS/b0.nii.gz /INPUTS/T1.nii.gz $MNI_T1_1_MM_FILE /extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c_2_5.nii.gz /OUTPUTS

# Run inference
NUM_FOLDS=5
for i in $(seq 1 $NUM_FOLDS);
  do echo Performing inference on FOLD: "$i"
  python3.6 /extra/inference.py /OUTPUTS/T1_norm_lin_atlas_2_5.nii.gz /OUTPUTS/b0_d_lin_atlas_2_5.nii.gz /OUTPUTS/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz /extra/dual_channel_unet/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth
done

# Take mean
echo Taking ensemble average
fslmerge -t /OUTPUTS/b0_u_lin_atlas_2_5_merged.nii.gz /OUTPUTS/b0_u_lin_atlas_2_5_FOLD_*.nii.gz
fslmaths /OUTPUTS/b0_u_lin_atlas_2_5_merged.nii.gz -Tmean /OUTPUTS/b0_u_lin_atlas_2_5.nii.gz

# Apply inverse xform to undistorted b0
echo Applying inverse xform to undistorted b0
antsApplyTransforms -d 3 -i /OUTPUTS/b0_u_lin_atlas_2_5.nii.gz -r /INPUTS/b0.nii.gz -n BSpline -t [/OUTPUTS/epi_reg_d_ANTS.txt,1] -t [/OUTPUTS/ANTS0GenericAffine.mat,1] -o /OUTPUTS/b0_u.nii.gz

# Smooth image
echo Applying slight smoothing to distorted b0
fslmaths /INPUTS/b0.nii.gz -s 1.15 /OUTPUTS/b0_d_smooth.nii.gz

if [[ $TOPUP -eq 1 ]]; then
    # Merge results and run through topup
    echo Running topup
    fslmerge -t /OUTPUTS/b0_all.nii.gz /OUTPUTS/b0_d_smooth.nii.gz /OUTPUTS/b0_u.nii.gz
    topup -v --imain=/OUTPUTS/b0_all.nii.gz --datain=/INPUTS/acqparams.txt --config=/extra/synb0.cnf --iout=/OUTPUTS/b0_all_topup.nii.gz --out=/OUTPUTS/topup
fi


# Done
echo FINISHED!!!
