import os
import sys
import glob
import math

from random import shuffle

import numpy as np

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
#from torchvision import datasets, transforms

import nibabel as nib

import torch
import torch.nn as nn

import util

from model import UNet3D


def inference(T1_path, b0_d_path, model, device):
    # Eval mode
    model.eval()

    # Get image
    img_T1 = np.expand_dims(util.get_nii_img(T1_path), axis=3)
    img_b0_d = np.expand_dims(util.get_nii_img(b0_d_path), axis=3)

    # Pad array since I stupidly used template with dimensions not factorable by 8
    # Assumes input is (77, 91, 77) and pad to (80, 96, 80) with zeros
    img_T1 = np.pad(img_T1, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')
    img_b0_d = np.pad(img_b0_d, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')

    # Convert to torch img format
    img_T1 = util.nii2torch(img_T1)
    img_b0_d = util.nii2torch(img_b0_d)

    # Normalize data
    img_T1 = util.normalize_img(img_T1, 150, 0, 1, -1)
    max_img_b0_d = np.percentile(img_b0_d, 99)
    min_img_b0_d = 0
    img_b0_d = util.normalize_img(img_b0_d, max_img_b0_d, min_img_b0_d, 1, -1)

    # Set "data"
    img_data = np.concatenate((img_b0_d, img_T1), axis=1)

    # Send data to device
    img_data = torch.from_numpy(img_data).float().to(device)

    # Pass through model
    # test torch autocast to float16
    with torch.autocast(device_type='cpu', dtype=torch.bfloat16):
        img_model = model(img_data)
    #img_model = model(img_data)

    # Unnormalize model
    img_model = util.unnormalize_img(img_model, max_img_b0_d, min_img_b0_d, 1, -1)

    # Remove padding
    img_model = img_model[:, :, 2:-1, 2:-1, 3:-2]

    # Return model
    return img_model


if __name__ == '__main__':
    # Get input arguments ----------------------------------#
    print(sys.path)
    T1_input_path = sys.argv[1]
    b0_input_path = sys.argv[2]
    b0_output_path = sys.argv[3]
    model_path = sys.argv[4]

    print('T1 input path: ' + T1_input_path)
    print('b0 input path: ' + b0_input_path)
    print('b0 output path: ' + b0_output_path)
    print('Model path: ' + model_path)

    # Run code ---------------------------------------------#

    # Get device
    device = torch.device("cpu")

    # Get model
    model = UNet3D(2, 1).to(device)
    model.load_state_dict(torch.load(model_path, map_location=device))

    # Inference
    img_model = inference(T1_input_path, b0_input_path, model, device)

    # Save
    nii_template = nib.load(b0_input_path)
    nii = nib.Nifti1Image(util.torch2nii(img_model.detach().cpu()), nii_template.affine, nii_template.header)
    nib.save(nii, b0_output_path)
