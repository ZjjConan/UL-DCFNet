% function ulDCFNetTrain(etime)
    % script for self-supervised learning using dcfnet
    clc;
    
    videoName = 'SR (1994)';  
%     if nargin < 2
%     etime = 1;
%     end
    etime = 1;
    %% general settings
%     if etime == 1
%         opts.imdbDir = ['data/imdb/' videoName '_nobbrm_imdb.mat'];
%         opts.saveModelName = ['DCFNet - ' videoName ' - nbbrm'];
%     else
%         opts.imdbDir = ['data/imdb/' videoName '_imdb.mat'];
%         opts.saveModelName = ['DCFNet - ' videoName ' - nfba'];
%     end
    opts.imdbDir = ['data/imdb/' videoName '_imdb.mat'];
    
    opts.outDir = 'data/snapshot/';
    opts.outPairImgDir = 'data/pairs/';
    opts.saveInternalPairs = false;
    opts.gpus = [1];

%     imdb = load(opts.imdbDir);
    
    %% setup network
    netOpts.lossType = 1;
    netOpts.inputSize = 125;
    netOpts.padding = 2;
    netOpts.averageImage = reshape(single([123,117,104]), [1,1,3]);
    net = initDCFNet(netOpts);
    net.meta.normalization.averageImage = netOpts.averageImage;

    %% online tracking opts
    opts.trackOpts.gpus = opts.gpus;
    opts.trackOpts.visualization = 0;
    opts.trackOpts.trackingFeatrLayer = 'conv1s';
    opts.trackOpts.numImagesPerClip = 1;
    opts.trackOpts.maxInterval = 10;
    opts.trackOpts.trackingNumClips = numel(imdb.images.data);
    opts.trackOpts.selectNums = 16;
    opts.trackOpts.selectThre = 0.7;
    opts.trackOpts.FBABatchSize = 10;
    opts.trackOpts.trackingFcn = @DCFNetFBWTracking;  
    opts.trackOpts.getBatchFcn = @getBatchFromClip;
    opts.trackOpts.FBA = true;
    opts.trackOpts.gridGenerator = ...
        dagnn.AffineGridGenerator('Ho', netOpts.inputSize, ...
                                  'Wo', netOpts.inputSize); 
    
    opts.trackOpts.grayImage = true;
    opts.trackOpts.grayProb = 0.25;
    opts.trackOpts.blurImage = true;
    opts.trackOpts.blurSigma = 4;
    opts.trackOpts.blurProb = 0.25;
    opts.trackOpts.rotateImage = true;
    opts.trackOpts.rotateProb = 0.25;
    opts.trackOpts.rotateRange = [-pi pi]/3;
     
    % trainOpts
    opts.trainOpts.randpermute = true;
    opts.trainOpts.momentum = 0.9;
    opts.trainOpts.weightDecay = 0.0005;
    opts.trainOpts.learningRate = logspace(-2, -3, 10);
    opts.trainOpts.numEpochs = numel(opts.trainOpts.learningRate);
    opts.trainOpts.derOutputs = {'objective', 1};
    opts.trainOpts.continue = false;
 
    opts.trainOpts.getDataFcn = @DCFNetGetData;
    opts.trainOpts.getBatchFcn = ...
        @(x,y) getTrainBatch(x, y, 'gpus', [1], ...
                   'averageImage', netOpts.averageImage, ...
                   'augFlip', true, 'flipProb', 0.25);
               
    net = ul_get_dataoffline(net, imdb, opts); 
    
%     modelPath = @(ep) fullfile(opts.outDir, sprintf('net-epoch-%d.mat', ep));
%     for i = 1:opts.trainOpts.numEpochs
%         load(modelPath(i));
%         net = deployDCFNet(dagnn.DagNN.loadobj(net));
%         save(fullfile(opts.saveModelDir, [opts.saveModelName ' - e' num2str(i) '.mat']), 'net');
%     end
% end