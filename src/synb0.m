function synb0(Dmprspace, mpr, Dresults, name, dataset)
   %{ 
     input:
        Dmprspace: directory where intermediate output will be stored
        mpr: T1 file
        Dresults: output directory for b0 synthesis
        name: output file name (subject name typical)
        dataset: output directory of RGB conversion
    %}

    if (~isdeployed)
        addpath('/home-nfs/masi-shared-home/home/local/VANDERBILT/hansencb/NIFTI');
    end

    datRGBtriDWMRI(Dmprspace, mpr, name, dataset);
    
    pix2pix_commands = [strcat("env -i /usr/bin/python /synb0/python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot ", dataset, "-axi --name b0ganRGB-axi_pix2pix --model pix2pix --results_dir ", Dresults ," --which_direction AtoB  --how_many  10000000")
                        strcat("env -i /usr/bin/python /synb0/python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot ", dataset, "-sag --name b0ganRGB-sag_pix2pix --model pix2pix --results_dir ", Dresults ," --which_direction AtoB  --how_many  10000000")
                        strcat("env -i /usr/bin/python /synb0/python/pytorch-CycleGAN-and-pix2pix/test.py --dataroot ", dataset, "-cor --name b0ganRGB-cor_pix2pix --model pix2pix --results_dir ", Dresults ," --which_direction AtoB  --how_many  10000000")];
                    
    for i = 1:length(pix2pix_commands)
        system(pix2pix_commands(i));
    end
    
    datRGBtriDWMRIrecon(Dmprspace, Dresults, name, dataset,mpr);

end