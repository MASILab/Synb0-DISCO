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
from torchvision import datasets, transforms

import nibabel as nib

import torch
import torch.nn as nn

import util

from model import UNet3D


def get_data_and_target(synb0prep_dir_path, device):
    # Get paths
    T1_path = os.path.join(synb0prep_dir_path, 'T1_norm_lin_atlas_2_5.nii.gz')
    b0_d_path = os.path.join(synb0prep_dir_path, 'b0_d_lin_atlas_2_5.nii.gz')
    b0_u_path = os.path.join(synb0prep_dir_path, 'b0_u_lin_atlas_2_5.nii.gz')
    mask_path = os.path.join(synb0prep_dir_path, 'mask_lin.nii.gz')

    # Get image
    img_T1 = np.expand_dims(util.get_nii_img(T1_path), axis=3)
    img_b0_d = np.expand_dims(util.get_nii_img(b0_d_path), axis=3)
    img_b0_u = np.expand_dims(util.get_nii_img(b0_u_path), axis=3)
    img_mask = np.expand_dims(util.get_nii_img(mask_path), axis=3)

    # Pad array since I stupidly used template with dimensions not factorable by 8
    # Assumes input is (77, 91, 77) and pad to (80, 96, 80) with zeros
    img_T1 = np.pad(img_T1, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')
    img_b0_d = np.pad(img_b0_d, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')
    img_b0_u = np.pad(img_b0_u, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')
    img_mask = np.pad(img_mask, ((2, 1), (3, 2), (2, 1), (0, 0)), 'constant')

    # Convert to torch img format
    img_T1 = util.nii2torch(img_T1)
    img_b0_d = util.nii2torch(img_b0_d)
    img_b0_u = util.nii2torch(img_b0_u)
    img_mask = util.nii2torch(img_mask) != 0

    # Normalize data
    img_T1 = util.normalize_img(img_T1, 150, 0, 1, -1)  # Based on freesurfers T1 normalization
    max_img_b0_d = np.percentile(img_b0_d, 99)          # This usually makes majority of CSF be the upper bound
    min_img_b0_d = 0                                    # Assumes lower bound is zero (direct from scanner)
    img_b0_d = util.normalize_img(img_b0_d, max_img_b0_d, min_img_b0_d, 1, -1)
    img_b0_u = util.normalize_img(img_b0_u, max_img_b0_d, min_img_b0_d, 1, -1) # Use min() and max() from distorted data

    # Set "data" and "target"
    img_data = np.concatenate((img_b0_d, img_T1), axis=1)
    img_target = img_b0_u

    # Send data to device
    img_data = torch.from_numpy(img_data).float().to(device)
    img_target = torch.from_numpy(img_target).float().to(device)
    img_mask = torch.from_numpy(np.array(img_mask, dtype=np.uint8))

    return img_data, img_target, img_mask


def compute_loss(derivatives_path, model, device):
    # Get blip directories
    synb0prep_dir_paths = glob.glob(os.path.join(derivatives_path, 'synb0prep_*'))

    # Get predicted images and masks
    img_models = []
    img_targets = []
    img_masks = []
    for synb0prep_dir_path in synb0prep_dir_paths:
        # Get data, target, and mask
        img_data, img_target, img_mask = get_data_and_target(synb0prep_dir_path, device)

        # Pass through model
        img_model = model(img_data)

        # Append
        img_models.append(img_model)
        img_targets.append(img_target)
        img_masks.append(img_mask)

    # Compute loss
    loss = torch.zeros(1, 1, device=device) # Initialize to zero

    # First, get "truth loss"
    for idx in range(len(synb0prep_dir_paths)):
        # Get model, target, and mark
        img_model = img_models[idx]
        img_target = img_targets[idx]
        img_mask = img_masks[idx]

        # Compute loss
        loss += F.mse_loss(img_model[img_mask], img_target[img_mask])

    # Divide loss by number of synb0prep directories
    loss /= len(synb0prep_dir_paths)

    # Next, get "difference loss"
    if len(synb0prep_dir_paths) == 2:
        # Get model, target, and mark
        img_model1 = img_models[0]
        img_model2 = img_models[1]
        img_mask = img_masks[0] & img_masks[1]

        # Add difference loss
        loss += F.mse_loss(img_model1[img_mask], img_model2[img_mask])
    elif len(synb0prep_dir_paths) == 1:
        pass # Don't add any difference loss
    else:
        raise RunTimeError(train_dir_path + ': Only single and double blips are supported')

    return loss


def train(derivatives_path, model, device, optimizer):
    # Train mode
    model.train()

    # Zero gradient
    optimizer.zero_grad()

    # Compute loss
    loss = compute_loss(derivatives_path, model, device)

    # Compute gradient
    loss.backward()

    # Step optimizer
    optimizer.step()

    # Return loss
    return loss.item()


def validate(derivatives_path, model, device):
    # Eval mode
    model.eval()

    # Compute loss
    loss = compute_loss(derivatives_path, model, device)

    # Return loss
    return loss.item()


if __name__ == '__main__':
    # Get input arguments ----------------------------------#
    learning_subjects_path = sys.argv[1]
    test_subjects_path = sys.argv[2]
    num_fold = int(sys.argv[3])
    total_folds = int(sys.argv[4])
    results_dir_path = sys.argv[5]

    print('Learning subjects path: ' + str(learning_subjects_path))
    print('Test subjects path: ' + str(test_subjects_path))
    print('Fold number: ' + str(num_fold))
    print('Total folds: ' + str(total_folds))
    print('Results dir path: ' + results_dir_path)

    # Handle training/validation/test lists ----------------#

    # Read learning subjects
    with open(learning_subjects_path, 'r') as f:
        learning_subjects = np.asarray(f.read().splitlines())

    # Get fold indices
    idx_folds = np.array_split(np.arange(learning_subjects.size), total_folds)

    # Get validation indices
    idx_validation = idx_folds[num_fold-1]

    # Get training indices
    del idx_folds[num_fold - 1]
    idx_training = np.concatenate(idx_folds)

    # Get training and validation subjects
    training_subjects = learning_subjects[idx_training]
    validation_subjects = learning_subjects[idx_validation]

    # Read test subjects
    with open(test_subjects_path, 'r') as f:
        test_subjects = np.asarray(f.read().splitlines())

    print('Training subjects: ' + str(training_subjects))
    print('Validation subjects: ' + str(validation_subjects))
    print('Test subjects: ' + str(test_subjects))

    # Set params -------------------------------------------#

    seed = 1
    num_epochs = 100
    lr = 0.0001
    betas = (0.9, 0.999)
    weight_decay = 1e-5

    print('Seed: ' + str(seed))
    print('num_epochs: ' + str(num_epochs))
    print('learning rate: ' + str(lr))
    print('betas: ' + str(betas))
    print('weight decay: ' + str(weight_decay))

    # Run code ---------------------------------------------#

    # Get output prefix
    prefix = '_'.join(['num_fold', str(num_fold),
                       'total_folds', str(total_folds),
                       'seed', str(seed),
                       'num_epochs', str(num_epochs),
                       'lr', str(lr),
                       'betas', str(betas),
                       'weight_decay', str(weight_decay)])
    prefix = os.path.join(results_dir_path, prefix)

    # Log training and validation curve
    train_curve_path = prefix + '_train.txt'
    validation_curve_path = prefix + '_validation.txt'
    test_path = prefix + '_test.txt'
    open(train_curve_path, 'w').close()
    open(validation_curve_path, 'w').close()
    open(test_path, 'w').close()

    # Set seed
    torch.manual_seed(seed)

    # Get device
    device = torch.device("cuda")

    # Get model
    model = UNet3D(2, 1).to(device)

    # Get optimizer
    optimizer = optim.Adam(model.parameters(), lr=lr, betas=betas, weight_decay=weight_decay)

    # Train
    model_path_best = ''
    l_validation_best = float("inf")
    for num_epoch in range(num_epochs):
        print('Epoch: ' + str(num_epoch))

        # Train -------------------------------------------#

        # Jumble data set for each epoch
        shuffle(training_subjects)

        l_train_total = 0
        num_train_total = 0
        for training_subject in training_subjects:
            # Get sessions
            training_sessions = glob.glob(os.path.join(training_subject, '*'))
            for training_session in training_sessions:
                # Get derivatives
                derivatives_path = os.path.join(training_session, 'derivatives')

                # Train
                l_train = train(derivatives_path, model, device, optimizer)

                # Sum loss
                l_train_total += l_train

                # Increment
                num_train_total += 1

        l_train_mean = l_train_total/num_train_total
        print('Training loss: ' + str(l_train_mean))

        with open(train_curve_path, "a") as f:
            f.write(str(l_train_mean) + '\n')

        # Validate ----------------------------------------#

        l_validation_total = 0
        num_validation_total = 0
        for validation_subject in validation_subjects:
            # Get sessions
            validation_sessions = glob.glob(os.path.join(validation_subject, '*'))
            for validation_session in validation_sessions:
                # Get derivatives
                derivatives_path = os.path.join(validation_session, 'derivatives')

                # Validate
                l_validation = validate(derivatives_path, model, device)

                # Sum loss
                l_validation_total += l_validation

                # Increment
                num_validation_total += 1

        l_validation_mean = l_validation_total/num_validation_total
        print('Validation loss: ' + str(l_validation_mean))

        with open(validation_curve_path, "a") as f:
            f.write(str(l_validation_mean) + '\n')

        # Check if this is better
        if l_validation_mean < l_validation_best:
            print('Validation improved... check pointing')

            # Save
            model_path_best = prefix + '_num_epoch_' + str(num_epoch) + '.pth'
            torch.save(model.state_dict(), model_path_best)

            # Update
            l_validation_best = l_validation_mean

    # Test ----------------------------------------#
    print('Performing test on best validation model: ' + model_path_best)

    # Load best model
    model.load_state_dict(torch.load(model_path_best))

    # Test
    l_test_total = 0
    num_test_total = 0
    for test_subject in test_subjects:
        # Get sessions
        test_sessions = glob.glob(os.path.join(test_subject, '*'))
        for test_session in test_sessions:
            # Get derivatives
            derivatives_path = os.path.join(test_session, 'derivatives')

            # test
            l_test = validate(derivatives_path, model, device)

            # Sum loss
            l_test_total += l_test

            # Increment
            num_test_total += 1

    l_test_mean = l_test_total/num_test_total
    print('test loss: ' + str(l_test_mean))

    with open(test_path, "a") as f:
        f.write(str(l_test_mean) + '\n')
