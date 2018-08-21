function inputs = getTrainBatch(imdb, batch, varargin)
    opts.gpus = [];
    opts.averageImage = [];
    opts.augmentFlip = false; 
    
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
    
    inputs = {'target', target, 'search', search} ;
    
    if opts.augmentFlip
        if rand > 0.5
            inputs = {'target', target, 'search', fliplr(search)};
        end
    end
end