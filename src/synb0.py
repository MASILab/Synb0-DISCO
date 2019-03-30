import os

def synb0(nifti_path, Dmprspace, mpr, Dresults, name, dataset):
   #input:
   #   Dmprspace: directory where intermediate output will be stored
   #   mpr: T1 file
   #   Dresults: output directory for b0 synthesis
   #   name: output file name (subject name typical)
   #   dataset: output directory of RGB conversion
	
	mat_command = "matlab -nodisplay -nodesktop -r \"datRGBtriDWMRI('"+nifti_path+"', '"+Dmprspace+"', '"+mpr+"', '"+name+"', '"+dataset+"')\"; exit"
	#os.system(mat_command)
    
	pix2pix_commands = ["env -i /usr/bin/python ./python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot "+dataset+"-axi/b0ganRGBHCP-axi --name b0ganRGB-axi_pix2pix --model pix2pix --which_direction AtoB  --how_many  10000000", "env -i /usr/bin/python ./python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot "+dataset+"-sag/b0ganRGBHCP-sag --name b0ganRGB-sag_pix2pix --model pix2pix --which_direction AtoB  --how_many  10000000", "env -i /usr/bin/python ./python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot "+dataset+"-cor/b0ganRGBHCP-cor --name b0ganRGB-cor_pix2pix --model pix2pix --which_direction AtoB  --how_many  10000000"]
                
	for command in pix2pix_commands:
		os.system(command)

	#mat_command = "matlab -nodisplay -nodesktop -r \"datRGBtriDWMRIrecon('"+nifti_path+"', '"+Dmprspace+"', '"+Dresults+"', '"+name+"', '"+dataset+"');\"; exit"
	#os.system(mat_command)
