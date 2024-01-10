% Set environment
addpath('/home-nfs2/local/VANDERBILT/blaberj/notboxplot');
addpath('/home-nfs2/local/VANDERBILT/blaberj/distinguishable_colors');

% Get training dir path
train_dir_path = '/nfs/masi/blaberj/synb0_25iso/dual_channel_unet/train_lin';

% Plot training and validation curves
num_folds = 5;

% Get colors
colors = distinguishable_colors(5);

% Create plot
figure;

% Plot training/validation
subplot(1,2,1);
trains = [];
validations = [];
tests = [];
for i = 1:num_folds
    % train, validation, and test log path
    train_log_path = fullfile(train_dir_path, ['num_fold_' num2str(i) '_total_folds_' num2str(num_folds) '_seed_1_num_epochs_100_lr_0.0001_betas_(0.9, 0.999)_weight_decay_1e-05_train.txt']);
    validation_log_path = fullfile(train_dir_path, ['num_fold_' num2str(i) '_total_folds_' num2str(num_folds) '_seed_1_num_epochs_100_lr_0.0001_betas_(0.9, 0.999)_weight_decay_1e-05_validation.txt']);
    test_log_path = fullfile(train_dir_path, ['num_fold_' num2str(i) '_total_folds_' num2str(num_folds) '_seed_1_num_epochs_100_lr_0.0001_betas_(0.9, 0.999)_weight_decay_1e-05_test.txt']);
    
    % Read data
    trains = [trains dlmread(train_log_path)]; %#ok<AGROW>
    validations = [validations dlmread(validation_log_path)]; %#ok<AGROW>
    tests = [tests dlmread(test_log_path)]; %#ok<AGROW>
    
    % Plot
    plot(trains(:,i), 'color', colors(i,:), 'LineStyle', '-')
    hold on;
    plot(validations(:,i), 'color', colors(i,:), 'LineStyle', '--');
end

% Plot box plot
subplot(1,2,2);
notBoxPlot(tests);
set(gca, 'XLim', [0 2], 'YLim', [0.0111 0.0117]);