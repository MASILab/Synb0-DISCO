function datRGBtriDWMRI(Dmprspace, mpr, name, dataset)

	%{ 
         input:
			Dmprspace: directory where intermediate output will be stored
			mpr: T1 file
			name: output file name (subject name typical)
			dataset: output directory name
    %}

	if exist(Dmprspace, 'dir') ~= 7
		mkdir Dmprspace;
	end

	if exist([dataset '-axi']) ~=7
		mkdir([dataset '-axi' filesep 'test']);
	end

	if exist([dataset '-cor']) ~=7
		mkdir([dataset '-cor' filesep 'test']);
	end
	
	if exist([dataset '-sag']) ~=7
		mkdir([dataset '-sag' filesep 'test']);
    end
	
	atlas = '/synb0/icbm_avg_152_t1_tal_nlin_symmetric_VI.nii.gz';
	b0atlas = '/synb0/data/atlas-b0.nii.gz';
	
	atlasnii = load_nii(atlas);
	atlasb0nii = load_nii(b0atlas);
	masknii = load_nii('/synb0/icbm_avg_152_t1_tal_nlin_symmetric_VI_mask.nii.gz');
	
	TEMPss=[];
	
	sub = name;
	disp(sub)
	
	rmpr =  [Dmprspace name '-r-mpr.nii.gz'];
	system(['source /fsl/etc/fslconf/fsl.sh; '...
	    ' fslreorient2std ' mpr ' ' rmpr]);
	
	mpr = rmpr;
	
	
	%% Step 2: register MPR to MNI-152
	mprinmni = [Dmprspace name '-mpr-mni.nii.gz'];
	if(1) 
	    system(['source /fsl/etc/fslconf/fsl.sh; flirt ' ...
	        '-dof 12 -cost normcorr ' ...
	        '-in ' mpr ' ' ...
	        '-ref ' atlas ' ' ...
	        '-out ' mprinmni ' ' ...
	        '-omat ' Dmprspace name '-mpr-mni.mat ' ])
	end
	
	
	%% Step 4: Normalize the T1's to the MNI contrast
	normmprinmni = [Dmprspace name '-mpr-mni-norm.nii.gz'];
	if(1) %length(dir(normmprinmni))<1)
	    
	    mprnii = load_nii(mprinmni);
	    
	    [n,x]=hist(double(mprnii.img(masknii.img(:)>0)),256);
	    [na,xa]=hist(double(atlasnii.img(masknii.img(:)>0)),256);
	    
	    cn = cumsum(n)/sum(n);
	    cna = cumsum(na)/sum(na);
	    
	    mnx = x(min(find(cn>0.75)));
	    mxx = x(max(find(cn<0.25)));
	    mnxa = xa(min(find(cna>0.75)));
	    mxxa = xa(max(find(cna<0.25)));
	    
	    mprnii.img=(mxxa)/(mxx)*(mprnii.img);
	    mprnii.hdr.dime.datatype=16;
	    mprnii.hdr.dime.bitpix=32;
	    save_nii(mprnii,normmprinmni);
	end
	
	
	%% Step 5: write out PNGs
	
	mprnii  = load_nii(normmprinmni);
	
	
	dset = 'test';
	clear mprpng sspng
	for jSlice =  2:(size(mprnii.img,3)-1)
	    disp([j jSlice])
	    
	    filename = [name '-' num2str(jSlice)];
	    
	    mprpng(:,:,1) = floor(min(255,max(0,mprnii.img(:,:,jSlice-1))));
	    mprpng(:,:,2) = floor(min(255,max(0,mprnii.img(:,:,jSlice))));
	    mprpng(:,:,3) = floor(min(255,max(0,mprnii.img(:,:,jSlice+1))));
	    imwrite([uint8(mprpng) uint8(mprpng*0)],...
	        [dataset '-axi' filesep dset filesep filename '.png']);
	end
	
	clear mprpng sspng
	
	for jSlice =  2:(size(mprnii.img,2)-1)
	    disp([j jSlice])
	    
	    filename = [name '-' num2str(jSlice)];
	    
	    mprpng(:,:,1) = squeeze(floor(min(255,max(0,mprnii.img(:,jSlice-1,:)))));
	    mprpng(:,:,2) = squeeze(floor(min(255,max(0,mprnii.img(:,jSlice,:)))));
	    mprpng(:,:,3) = squeeze(floor(min(255,max(0,mprnii.img(:,jSlice+1,:)))));
	    imwrite([uint8(mprpng) uint8(mprpng*0)],...
	        [dataset '-cor'  filesep dset filesep filename '.png']);
	end
	
	clear mprpng sspng
	
	for jSlice =  2:(size(mprnii.img,1)-1)
	    disp([j jSlice])
	    
	    filename = [name '-' num2str(jSlice)];
	    
	    mprpng(:,:,1) = squeeze(floor(min(255,max(0,mprnii.img(jSlice-1,:,:)))));
	
	    mprpng(:,:,2) = squeeze(floor(min(255,max(0,mprnii.img(jSlice,:,:)))));
	
	    mprpng(:,:,3) = squeeze(floor(min(255,max(0,mprnii.img(jSlice+1,:,:)))));
	    imwrite([uint8(mprpng) uint8(0*mprpng)],...
	        [dataset  '-sag' filesep dset filesep filename '.png']);
	end
end
