try
    % set the target filename
    mpr = '/INPUTS/T1.nii.gz';
    % set directories for intermediate files
    dataset = '/dataset/';
    Dresults = '/results/';
    % set directory for output
    Dmprspace = '/OUTPUTS/';
    %set common file name
    name = 'disco';
    % run the pipeline
    synb0(Dmprspace, mpr, Dresults, name, dataset);
catch e
    getReport(e)
end
disp('Exiting...');
exit