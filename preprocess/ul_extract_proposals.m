function ul_extract_proposals(videoDir, varargin)
    opts.saveDir = '';
    opts.debug = false;
    
    opts.useFastStrategy = true;
    opts.maxImageSize = 500;
    opts.useThreads = 4;

    [opts, varargin] = vl_argparse(opts, varargin);
    

    [images, names] = ul_dir(videoDir, 'jpg');
    
    [~, vname, ~] = fileparts(videoDir);
    saveDir = fullfile(opts.saveDir, vname);
    ul_make_dir(saveDir);
    numImages = numel(images);
    
    baseImage = ul_read_img(images{1});
    [r, c, ~] = size(baseImage);
    scaleRatio = opts.maxImageSize / max(r, c);
    baseImage = imresize(baseImage, scaleRatio);
    
    for t = 1:opts.useThreads
        obj{t} = cv.SelectiveSearchSegmentation;
        obj{t}.setBaseImage(baseImage);
        if opts.useFastStrategy
            obj{t}.switchToSelectiveSearchFast;
        else
            obj{t}.switchToSelectiveSearchQuality;
        end
        obj{t}.clearImages;
    end
    
    tic
    for i = 1:numImages
        im = ul_read_img(images{i});
        im = imresize(im, scaleRatio);
        obj{1}.addImage(im);
        proposals = obj{1}.process / scaleRatio;
        obj{1}.clearImages;
        proposals(:, 1:2) = uint16(proposals(:, 1:2) + 1);
        if opts.debug
            ul_draw_bbox(imresize(im, 1/scaleRatio), proposals);
        end
        
        save_bbox_parfor(fullfile(saveDir, [names{i} '.mat']), proposals);
        if mod(i, 1000) == 0
            fprintf('%s: process %d / %d frame time %.2fs\n', mfilename, i, numImages, toc);
        end
    end
end

