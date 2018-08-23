% function ulDCFNetTrain(videoName, etime)
    % script for self-supervised learning using dcfnet
    clc;
    
    videoName = 'SR (1994)';  
%     if nargin < 2
        etime = 1;
%     end
    
    %% general settings
    opts.imdbDir = ['data/imdb/' videoName '_imdb.mat'];
    
    opts.outDir = 'data/snapshot/';
    opts.saveModelDir = 'F:/Research/tracker_zoo/DCFNet/model';
    opts.saveModelName = ['DCFNet - ' videoName];
    opts.outPairImgDir = 'data/pairs/';
    opts.saveInternalPairs = false;
    opts.gpus = [1];

    opts.outDir = fullfile(opts.outDir, [opts.saveModelName ' - r' num2str(etime)]);
    ulMakeDir(opts.outDir);

    imdb = load(opts.imdbDir);

    %% setup network
    netOpts.lossType = 1;
    netOpts.inputSize = 125;
    netOpts.padding = 2;
    net = initDCFNet(netOpts);

    %% online tracking opts
    opts.trackOpts.gpus = opts.gpus;
    opts.trackOpts.visualization = 0;
    opts.trackOpts.trackingFeatrLayer = 'conv1s';
    opts.trackOpts.numImagesPerClip = 4;
    opts.trackOpts.maxInterval = 50;
    opts.trackOpts.trackingNumPerEpoch = 3;
    opts.trackOpts.selectNums = 16;
    opts.trackOpts.selectThre = 0.7;
    opts.trackOpts.FBWBatchSize = 10;
    opts.trackOpts.trackingFcn = @DCFNetFBWTracking;  
    opts.trackOpts.getBatchFcn = @getBatchFromClip;

    % trainOpts
    opts.trainOpts.randpermute = true;
    opts.trainOpts.momentum = 0.9;
    opts.trainOpts.weightDecay = 0.0005;
    opts.trainOpts.learningRate = logspace(-2, -4, 20);
    opts.trainOpts.numEpochs = numel(opts.trainOpts.learningRate);
    opts.trainOpts.derOutputs = {'objective', 1};
    opts.trainOpts.continue = false;

    opts.trainOpts.getDataFcn = @DCFNetGetData;
    opts.trainOpts.getBatchFcn = ...
        @(x,y) getTrainBatch(x, y, 'gpus', [1], ...
                    'averageImage', net.meta.normalization.averageImage, ...
                    'augFlip', true, 'augGray', true);

    net = ul_cnn_train_dag(net, imdb, opts); 
    
    modelPath = @(ep) fullfile(opts.outDir, sprintf('net-epoch-%d.mat', ep));
    for i = 1:opts.trainOpts.numEpochs
        load(modelPath(i));
        net = deployDCFNet(dagnn.DagNN.loadobj(net));
        save(fullfile(opts.saveModelDir, [opts.saveModelName ' - e' num2str(i) '.mat']), 'net');
    end
