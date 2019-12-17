from synb0 import synb0

nifti_path = '/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/NIFTI'
Dmprspace='/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/scans/MPRAGE_MPRAGE/NIFTI'
mpr='/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/scans/MPRAGE_MPRAGE/NIFTI/MPRAGE.nii.gz'
Dresults='/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/scans/MPRAGE_MPRAGE'
name='test'
dataset='/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/scans/MPRAGE_MPRAGE'

synb0(nifti_path, Dmprspace, mpr, Dresults, name, dataset)
