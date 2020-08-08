# synb0_25iso_app
[Docker Hub](https://hub.docker.com/repository/docker/hansencb/synb0)

[Singularity Hub](https://singularity-hub.org/collections/4629)

# Run Instructions:
For docker:
```
sudo docker run --rm \
-v $(pwd)/INPUTS/:/INPUTS/ \
-v $(pwd)/OUTPUTS:/OUTPUTS/ \
-v <path to license.txt>:/extra/freesurfer/license.txt \
--user $(id -u):$(id -g) \
hansencb/synb0

Flags:
--notopup Skips the application of FSL's topup susceptability correction 
* as a default, we run topup for you, although you may want to run this on
 your own (for example with your own config file, or if you would like to 
 utilize multiple b0's)

See INPUTS/OUTPUTS sections below.
In short, if within your current directory you have your INPUTS 
and OUTPUTS folder, you can run this command copy/paste with the 
only change being <path to license.txt> should point to 
freesurfer licesnse.txt file on your system.

If INPUTS and OUTPUTS are not within your current directory, you
will need to change $(pwd)/INPUTS/ to the full path to your 
input directory, and similarly for OUTPUTS.

*** For Mac users, Docker defaults allows only 2gb of RAM 
and 2 cores - we suggest giving Docker access to >8Gb 
of RAM
*** Additionally on MAC, if permissions issues prevent binding the
path to the license.txt file, we suggest moving the freesurfer
license.txt file to the current path and replacing the path line to
" $(pwd)/license.txt:/extra/freesurfer/license.txt "
```
For singularity:
```
singularity run -e \
-B INPUTS/:/INPUTS \
-B OUTPUTS/:/OUTPUTS \
-B <path to license.txt>:/extra/freesurfer/license.txt \
shub://hanscol/synb0

<path to license.txt> should point to freesurfer licesnse.txt file

Flags:
--notopup Skips the application of FSL's topup susceptability correction 
* as a default, we run topup for you, although you may want to run this on
 your own (for example with your own config file, or if you would like to 
 utilize multiple b0's)
```
INPUTS:
```
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
```
Without singularity or Docker:
```
If you choose to run this  in bash, the script that is containerized is located in
src/pipeline.sh. The paths in pipeline.sh are specific to the docker/singularity file
system, but the processing can be replicated using the scripts in src.

These utilize freesurfer, FSL, ANTS, and a python environment with pytorch.
```

OUTPUTS:
```
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
```

AFTER RUNNING:
```
After running, we envision using the topup outputs directly with FSL's 
eddy command, exactly as would be done if a full set of reverse PE 
scans was acquired. For example:

eddy --imain=path/to/diffusiondata.nii.gz --mask=path/to/brainmask.nii.gz \
--acqp=path/to/acqparams.txt --index=path/to/index.txt \
--bvecs=path/to/bvecs.txt --bvals=path/to/bvals.txt 
--topup=path/to/OUTPUTS/topup --out=eddy_unwarped_images

where imain is the original diffusion data, mask is a brain mask, acqparams
is from before, index is the traditional eddy index file which contains an 
index (most likely a 1) for every volume in the diffusion dataset, topup points 
to the output of the singularity/docker pipeline, and out is the eddy-corrected
images utilizing the field coefficients from the previous step.

Alternatively, if you choose to run --notopup flag, the file you are interested in
is b0_all. This is a concatenation of the real b0 and the synthesized undistorted
b0. We run topup with this file, although you may chose to do so utilizing your 
topup version or config file. 

