# synb0_25iso_app
[Docker Hub](https://hub.docker.com/r/justinblaber/synb0_25iso/tags/)

[Singularity Hub](https://www.singularity-hub.org/collections/3102)

# Run Instructions:
For docker:
```
sudo docker run --rm \
-v $(pwd)/INPUTS/:/INPUTS/ \
-v $(pwd)/OUTPUTS:/OUTPUTS/ \
-v <path to license.txt>:/extra/freesurfer/license.txt \
--user $(id -u):$(id -g) \
justinblaber/synb0_25iso
```
For singularity:
```
singularity run -e \
-B INPUTS/:/INPUTS \
-B OUTPUTS/:/OUTPUTS \
-B <path to license.txt>:/extra/freesurfer/license.txt \
shub://justinblaber/synb0_25iso_app

<path to license.txt> should point to freesurfer licesnse.txt file

INPUTS directory must contain the following:
b0.nii.gz, T1.nii.gz, and acqparams.txt

b0.nii.gz includes the non-diffusion weighted image(s). 
T1.nii.gz is the T1-weighted image.
acqparams.txt describes the acqusition parameters, and is described in detail 
on the FslWiki for topup (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup).Briefly,
it describes the direction of distortion and tells TOPUP that the synthesized image
has an effective echo spacing of 0 (infinite bandwidth). An example acqparams.txt is
displayed below, in which distortion is in the second dimension, note that the second
row corresponds to the synthesized, undistorted, b0:
$ cat acqparams.txt 
0 1 0 0.062
0 1 0 0.000

After running, the outputs directory contains the following:
T1_mask.nii.gz: masked T1   
T1_norm.nii.gz: normalized T1
epi_reg_d.mat: epi_reg b0 to T1 in FSL format
epi_reg_d_ANTS.txt: epi_reg to T1 in ANTS format

Ants registration of T1_norm to/from MNI space:
ANTS0GenericAffine.mat
ANTS1InverseWarp.nii.gz  
ANTS1Warp.nii.gz
   
T1_norm_lin_atlas_2_5.nii.gz: linear transform T1 to MNI   
b0_d_lin_atlas_2_5.nii.gz  : linear transform distorted b0 in MNI space   
T1_norm_nonlin_atlas_2_5.nii.gz: nonlinear transform T1 to MNI   
b0_d_nonlin_atlas_2_5.nii.gz  : nonlinear transform distorted b0 in MNI space  

Inferences (predictions) for each of five folds:
T1 input path: /OUTPUTS/T1_norm_lin_atlas_2_5.nii.gz
b0 input path: /OUTPUTS/b0_d_lin_atlas_2_5.nii.gz
b0_u_lin_atlas_2_5_FOLD_1.nii.gz  
b0_u_lin_atlas_2_5_FOLD_2.nii.gz  
b0_u_lin_atlas_2_5_FOLD_3.nii.gz  
b0_u_lin_atlas_2_5_FOLD_4.nii.gz  
b0_u_lin_atlas_2_5_FOLD_5.nii.gz  

Ensemble average of inferences:
b0_u_lin_atlas_2_5_merged.nii.gz  
b0_u_lin_atlas_2_5.nii.gz         

b0_u.nii.gz: Syntehtic b0 native space                      

b0_d_smooth.nii.gz: smoothed b0

b0_all.nii.gz: stack of distorted and synthetized image as input to topup        

topup outputs to be used for eddy:
topup_movpar.txt
b0_all_topup.nii.g
b0_all.topup_log         
b0_topup.nii.gz                            
topup_fieldcoef.nii.gz
