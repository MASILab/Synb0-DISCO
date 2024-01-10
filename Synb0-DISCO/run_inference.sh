#!/bin/bash

export ROOT_DIR=/Users/elianaphillips/Desktop/NCIRE/Synb0-DISCO

MNI_T1_1_MM_FILE=$ROOT_DIR/atlases/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

# Set paths for inputs and outputs
INPUTS=$1
OUTPUTS=$2

# Set up virtual env
export VENVPATH=$ROOT_DIR/venv 
source $VENVPATH/bin/activate

# Run inference
NUM_FOLDS=5
for i in $(seq 1 $NUM_FOLDS);
  do echo Performing inference on FOLD: "$i"
  python3 $ROOT_DIR/inference.py $OUTPUTS/T1_norm_lin_atlas_2_5.nii.gz $OUTPUTS/b0_d_lin_atlas_2_5.nii.gz $OUTPUTS/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz $ROOT_DIR/train_lin/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth
done

