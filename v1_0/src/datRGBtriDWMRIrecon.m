function datRGBtriDWMRIrecon(Dmprspace, Dresults, name, dataset, mpr)
  
	%cd('./data')
	
	%% CONTROL VARS
	models = {'b0ganRGB-axi_pix2pix','b0ganRGB-cor_pix2pix','b0ganRGB-sag_pix2pix'};
	subD ='/test_latest/images/';
	%% SET THE ABOVE AND MAKE THE -axi. -cor, -sag dataset directories (and test subdir)
	
	atlas = '/synb0/icbm_avg_152_t1_tal_nlin_symmetric_VI.nii.gz';
	b0atlas = '/synb0/data/atlas-b0.nii.gz';
	
	atlasnii = load_nii(atlas);
	atlasb0nii = load_nii(b0atlas);
	masknii = load_nii('/synb0/icbm_avg_152_t1_tal_nlin_symmetric_VI_mask.nii.gz')
	
	TEMPss=[];
	

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % RECON HERE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
	sub = name;
	mprinmni = [Dmprspace name '-mpr-mni.nii.gz'];
    normmprinmni = [Dmprspace name '-mpr-mni-norm.nii.gz'];
    mprnii  = load_nii(normmprinmni);
    dset = 'test';
    ssnii = mprnii; ssnii.img=0*mprnii.img;
    
    
    jModel = 1;
    for jSlice =  2:(size(mprnii.img,3)-1)
        disp([j jSlice])
        files = dir([Dresults filesep models{jModel} subD  sub '-' num2str(jSlice) '_*fake*']);
        %files = dir([Dresults '*' sub '*' num2str(jSlice) 'fake*png']);
        png = imread([Dresults filesep models{jModel} subD  files(1).name]);
        ssnii.img(:,:,jSlice-1) = ssnii.img(:,:,jSlice-1)+double(imresize(png(:,:,1),[size(mprnii.img,1) size(mprnii.img,2)]));
        ssnii.img(:,:,jSlice) = ssnii.img(:,:,jSlice)+double(imresize(png(:,:,2),[size(mprnii.img,1) size(mprnii.img,2)]));
        ssnii.img(:,:,jSlice+1) = ssnii.img(:,:,jSlice+1)+double(imresize(png(:,:,3),[size(mprnii.img,1) size(mprnii.img,2)]));
        
    end
    ssnii.img=ssnii.img/3;
    
    ssest =  [Dmprspace sub '-r-mpr-ss-est-3-' models{jModel} '.nii.gz'];
    save_nii(ssnii,ssest);
    
    
    jModel = 2;
    ssnii = mprnii; ssnii.img=0*mprnii.img;
    for jSlice =  2:(size(mprnii.img,2)-1)
        disp([j jSlice])
        
        %filename = [subjs(j).name '-' num2str(jSlice)];
        
        disp([j jSlice])
        files = dir([Dresults filesep models{jModel} subD  sub '-' num2str(jSlice) '_*fake*']);
        %files = dir([Dresults '*' sub '*' num2str(jSlice) 'fake*png']);
        png = imread([Dresults filesep models{jModel} subD  files(1).name]);
        
        ssnii.img(:,jSlice-1,:) = ssnii.img(:,jSlice-1,:)+permute(double(imresize(png(:,:,1),[size(mprnii.img,1) size(mprnii.img,3)])),[1 3 2]);
        ssnii.img(:,jSlice,:) =  ssnii.img(:,jSlice,:)+permute(double(imresize(png(:,:,2),[size(mprnii.img,1) size(mprnii.img,3)])),[1 3 2]);
        ssnii.img(:,jSlice+1,:) =  ssnii.img(:,jSlice+1,:)+permute(double(imresize(png(:,:,3),[size(mprnii.img,1) size(mprnii.img,3)])),[1 3 2]);
        
        
    end
    ssnii.img=ssnii.img/3;
    
    ssest =  [Dmprspace sub '-r-mpr-ss-est-3-' models{jModel} '.nii.gz'];
    save_nii(ssnii,ssest);
    
    
    jModel = 3;
    ssnii = mprnii; ssnii.img=0*mprnii.img;
    for jSlice =  2:(size(mprnii.img,1)-1)
        disp([j jSlice])
        
        %filename = [subjs(j).name '-' num2str(jSlice)];
        
        files = dir([Dresults filesep models{jModel} subD  sub '-' num2str(jSlice) '_*fake*']);
        
        png = imread([Dresults filesep models{jModel} subD  files(1).name]);
        
        ssnii.img(jSlice-1,:,:) = ssnii.img(jSlice-1,:,:)+permute(double(imresize(png(:,:,1),[size(mprnii.img,2) size(mprnii.img,3)])),[3 1 2]);
        ssnii.img(jSlice,:,:) = ssnii.img(jSlice,:,:)+permute(double(imresize(png(:,:,2),[size(mprnii.img,2) size(mprnii.img,3)])),[3 1 2]);
        ssnii.img(jSlice+1,:,:) = ssnii.img(jSlice+1,:,:)+permute(double(imresize(png(:,:,3),[size(mprnii.img,2) size(mprnii.img,3)])),[3 1 2]);
        
    end
    ssnii.img=ssnii.img/3;
    ssest =  [Dmprspace sub '-r-mpr-ss-est-3-' models{jModel} '.nii.gz'];
    save_nii(ssnii,ssest);
    
    % Step 7: Train a model for each block of 5 slices
    clear S

    for jModel = 1:3
        S{jModel} =  load_nii([Dmprspace sub '-r-mpr-ss-est-3-' models{jModel} '.nii.gz']);
        if(jModel==1)
            img = S{jModel}.img;
        else
            img(:,:,:,jModel) = S{jModel}.img;
        end
    end
    img = mean(img,4);
    S = S{jModel};
    S.img = img;
    save_nii(S,[Dmprspace sub '-r-mpr-ss-est-3-' '-RGB-triplanar-mean-' '.nii.gz'])

    system(['source /fsl/etc/fslconf/fsl.sh; convert_xfm ' ...
        '-omat ' Dmprspace name '-mpr-mni-inverse.mat '  ...
        '-inverse ' Dmprspace name '-mpr-mni.mat ' ])

    system(['source /fsl/etc/fslconf/fsl.sh; flirt ' ...
        '-in ' [Dmprspace sub '-r-mpr-ss-est-3-' '-RGB-triplanar-mean-' '.nii.gz'] ' ' ...
        '-ref ' mpr ' ' ...
        '-out ' [Dmprspace sub '-r-mpr-ss-est-3-' '-RGB-triplanar-mean-' 'ORIG.nii.gz'] ' ' ...
        '-applyxfm -init ' Dmprspace name '-mpr-mni-inverse.mat ' ])
end
