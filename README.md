# Synb0-DISCO

## Contents

* [Overview](#overview)
* [Dockerized Application](#dockerized-application)
* [Docker Instructions](#docker-instructions)
* [Singularity Instructions](#singularity-instructions)
* [Non-containerized Instructions](#non-containerized-instructions)
* [Flags](#flags)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [After Running](#after-running)

## Overview

This repository implements the paper "Synthesized b0 for diffusion distortion correction" and "Distortion correction of diffusion weighted MRI without reverse phase-encoding scans or field-maps". 

This tool aims to enable susceptibility distortion correction with historical and/or limited datasets that do not include specific sequences for distortion correction (i.e. reverse phase-encoded scans). In short, we synthesize an "undistorted" b=0 image that matches the geometry of structural T1w images and also matches the contrast from diffusion images. We can then use this 'undistorted' image in standard pipelines (i.e. TOPUP) and tell the algorithm that this synthetic image has an infinite bandwidth. Note that the processing below enables both image synthesis, and also synthesis + full pipeline correction, if desired. 

**Please use the following citations to refer to this work:**

Schilling KG, Blaber J, Hansen C, Cai L, Rogers B, Anderson AW, Smith S, Kanakaraj P, Rex T, Resnick SM, Shafer AT, Cutting LE, Woodward N, Zald D, Landman BA. Distortion correction of diffusion weighted MRI without reverse phase-encoding scans or field-maps. PLoS One. 2020 Jul 31;15(7):e0236418. doi: 10.1371/journal.pone.0236418. PMID: 32735601; PMCID: PMC7394453.

Schilling KG, Blaber J, Huo Y, Newton A, Hansen C, Nath V, Shafer AT, Williams O, Resnick SM, Rogers B, Anderson AW, Landman BA. Synthesized b0 for diffusion distortion correction (Synb0-DisCo). Magn Reson Imaging. 2019 Dec;64:62-70. doi: 10.1016/j.mri.2019.05.008. Epub 2019 May 7. PMID: 31075422; PMCID: PMC6834894.

## Dockerized Application

For deployment we provide a [Docker container](https://hub.docker.com/repository/docker/leonyichencai/synb0-disco) which uses the trained model to predict the undistorted b0 to be used in susceptability distortion correction for diffusion weighted MRI. For those who prefer, Docker containers can be converted to Singularity containers (see below).

## Docker Instructions:

```
sudo docker run --rm \
-v $(pwd)/INPUTS/:/INPUTS/ \
-v $(pwd)/OUTPUTS:/OUTPUTS/ \
-v <path to license.txt>:/extra/freesurfer/license.txt \
--user $(id -u):$(id -g) \
leonyichencai/synb0-disco:v3.1
<flags>
```

* If within your current directory you have your INPUTS and OUTPUTS folder, you can run this command copy/paste with the only change being \<path to license.txt\> should point to the freesurfer license.txt file on your system.
* If INPUTS and OUTPUTS are not within your current directory, you will need to change $(pwd)/INPUTS/ to the full path to your input directory, and similarly for OUTPUTS.
* For Mac users, Docker defaults allows only 2gb of RAM and 2 cores - we suggest giving Docker access to >13Gb of RAM 
* Additionally on MAC, if permissions issues prevent binding the path to the license.txt file, we suggest moving the freesurfer license.txt file to the current path and replacing the path line to " $(pwd)/license.txt:/extra/freesurfer/license.txt "

## Singularity Instructions

First, build the synb0.simg container in the current directory:

```
singularity pull docker://leonyichencai/synb0-disco:v3.1
```

Then, to run the synb0.simg container:

```
singularity run -e \
-B INPUTS/:/INPUTS \
-B OUTPUTS/:/OUTPUTS \
-B <path to license.txt>:/extra/freesurfer/license.txt \
<path to synb0.simg>
<flags>
```

* \<path to license.txt\> should point to freesurfer licesnse.txt file
* \<path to synb0.simg\> should point to the singularity container 

## Non-containerized Instructions

If you choose to run this in bash, the primary script is located in src/pipeline.sh. The paths in pipeline.sh are specific to the docker/singularity file
systems, but the processing can be replicated using the scripts in src. These utilize freesurfer, FSL, ANTS, and a python environment with pytorch.

## Flags:

**--notopup**

Skip the application of FSL's topup susceptibility correction. As a default, we run topup for you, although you may want to run this on your own (for example with your own config file, or if you would like to utilize multiple b0's). If desired, you can concatenate the original (distorted) b=0 and the sythesized b=0 with: "fslmerge -t /OUTPUTS/b0_all.nii.gz /OUTPUTS/b0_d_smooth.nii.gz /OUTPUTS/b0_u.nii.gz"

**--stripped**

Lets the container know the supplied T1 has already been skull stripped. As a default, we assume it is not skull stripped. *Please note this feature requires a well-stripped T1 as stripping artifacts can affect performance.*

## Inputs

The INPUTS directory must contain the following:
* b0.nii.gz: the non-diffusion weighted image, must be a 3D image (either one b=0, or the average of all b=0 volumes)
* T1.nii.gz: the T1-weighted image (either raw or skull-stripped, see [Flags](#flags))
* acqparams.txt: A text file that describes the acqusition parameters, and is described in detail on the FslWiki for topup (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup). Briefly,
it describes the direction of distortion and tells TOPUP that the synthesized image has an effective echo spacing of 0 (infinite bandwidth). An example acqparams.txt is
displayed below, in which distortion is in the second dimension, note that the second row corresponds to the synthesized, undistorted, b0:
    ```
    $ cat acqparams.txt 
    0 1 0 0.062
    0 1 0 0.000
    ```

## Outputs

After running, the OUTPUTS directory contains the following preprocessing files:

* T1_mask.nii.gz: brain extracted (skull-stripped) T1 (a copy of the input if T1.nii.gz is already skull-stripped)
* T1_norm.nii.gz: normalized T1
* epi_reg_d.mat: epi_reg b0 to T1 in FSL format
* epi_reg_d_ANTS.txt: epi_reg to T1 in ANTS format
* ANTS0GenericAffine.mat: Affine ANTs registration of T1_norm to/from MNI space
* ANTS1Warp.nii.gz: Deformable ANTs registration of T1_norm to/from MNI space  
* ANTS1InverseWarp.nii.gz: Inverse deformable ANTs registration of T1_norm to/from MNI space  
* T1_norm_lin_atlas_2_5.nii.gz: linear transform T1 to MNI   
* b0_d_lin_atlas_2_5.nii.gz: linear transform distorted b0 in MNI space   
* T1_norm_nonlin_atlas_2_5.nii.gz: nonlinear transform T1 to MNI   
* b0_d_nonlin_atlas_2_5.nii.gz: nonlinear transform distorted b0 in MNI space  

The OUTPUTS directory also contains inferences (predictions) for each of five folds utilizing T1_norm_lin_atlas_2_5.nii.gz and b0_d_lin_atlas_2_5.nii.gz as inputs:

* b0_u_lin_atlas_2_5_FOLD_1.nii.gz  
* b0_u_lin_atlas_2_5_FOLD_2.nii.gz  
* b0_u_lin_atlas_2_5_FOLD_3.nii.gz  
* b0_u_lin_atlas_2_5_FOLD_4.nii.gz  
* b0_u_lin_atlas_2_5_FOLD_5.nii.gz  

After inference the ensemble average is taken in atlas space:

* b0_u_lin_atlas_2_5_merged.nii.gz  
* b0_u_lin_atlas_2_5.nii.gz         

It is then moved to native space for the undistorted, synthetic output:

* b0_u.nii.gz: Synthetic b0 native space                      

The undistorted synthetic output, and a smoothed distorted input can then be stacked together for topup:

* b0_d_smooth.nii.gz: smoothed b0
* b0_all.nii.gz: stack of distorted and synthetized image as input to topup        

Finally, the topup outputs to be used for eddy:

* topup_movpar.txt
* b0_all_topup.nii.gz
* b0_all.topup_log         
* topup_fieldcoef.nii.gz


## After Running

After running, we envision using the topup outputs directly with FSL's eddy command, exactly as would be done if a full set of reverse PE scans was acquired. For example:

```
eddy --imain=path/to/diffusiondata.nii.gz --mask=path/to/brainmask.nii.gz \
--acqp=path/to/acqparams.txt --index=path/to/index.txt \
--bvecs=path/to/bvecs.txt --bvals=path/to/bvals.txt 
--topup=path/to/OUTPUTS/topup --out=eddy_unwarped_images
```

where imain is the original diffusion data, mask is a brain mask, acqparams is from before, index is the traditional eddy index file which contains an index (most likely a 1) for every volume in the diffusion dataset, topup points to the output of the singularity/docker pipeline, and out is the eddy-corrected images utilizing the field coefficients from the previous step.

Alternatively, if you choose to run --notopup flag, the file you are interested in is b0_all. This is a concatenation of the real b0 and the synthesized undistorted b0. We run topup with this file, although you may chose to do so utilizing your topup version or config file. 
