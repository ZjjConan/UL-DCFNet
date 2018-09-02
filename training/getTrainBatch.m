function inputs = getTrainBatch(imdb, batch, varargin)
    opts.gpus = [];
    opts.averageImage = [];
    opts.augFlip = false;
    opts.flipProb = 0.1;
    
%     opts.augRotate = false;
%     opts.rotateProb = 0.1;
%     opts.rotateRange = [-60 60];
    
    [opts, varargin] = vl_argparse(opts, varargin);
    
    target = single(imdb.target(:,:,:,batch));
    search = single(imdb.search(:,:,:,batch));
    
    if opts.gpus
        target = gpuArray(target);
        search = gpuArray(search);
    end
    
    if ~isempty(opts.averageImage)
        if isscalar(opts.averageImage)
            target = target - opts.averageImage;
            search = search - opts.averageImage;
        else
            target = bsxfun(@minus, target, opts.averageImage);
            search = bsxfun(@minus, search, opts.averageImage);
        end
    end
 
    if opts.augFlip
        index = randperm(size(target,4), round(size(target,4) * opts.flipProb));
        for i = 1:numel(index)
            search(:,:,:,index(i)) = fliplr(search(:,:,:,index(i)));
        end
    end
    
%     if opts.augRotate
%         index = randperm(size(target,4), round(size(target,4) * opts.rotateProb));
%         theta = randi(opts.rotateRange, 1, numel(index));
%         for i = 1:numel(index)
%             search(:,:,:,index(i)) = imrotate(search(:,:,:,index(i)), theta(i), 'nearest', 'crop');
%         end 
%     end
    inputs = {'target', target, 'search', search} ;
end