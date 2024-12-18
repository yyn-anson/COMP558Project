% Ensure the required toolbox functions are on the MATLAB path
addpath(genpath('.'));

% Specify the input and output directories
inputDir = 'dataset/LD_dataset/val/offices'; 
outputDir = 'dataset/LD_dataset/new_val/offices'; 

% Get a list of images
fileList = dir(fullfile(inputDir, '*.png'));

% Properties to compute
propertiesToCompute = {'parallelism', 'separation', 'mirror', 'convexity', 'taper'};

for i = 1:length(fileList)
    fileName = fileList(i).name;
    inputFilePath = fullfile(inputDir, fileName);
    
    fprintf('Processing: %s\n', inputFilePath);
    
    % Step 1: Vectorize the line drawing
    im = imread(inputFilePath);
    
    if size(im,3) == 3
        im = rgb2gray(im);
    end
    imRGB = cat(3, im, im, im);
    
    % Use a unique temp file name for each iteration
    tempFile = fullfile(tempdir, sprintf('temp_line_drawing_%d.png', i));
    imwrite(imRGB, tempFile);
    
    vecLD = traceLineDrawingFromRGB(tempFile);
    
    % Step 2: Render line drawing as an image
    img_LD = renderLinedrawing(vecLD, []);
    
    [~, baseName, ~] = fileparts(fileName);
    outputLineDrawing = fullfile(outputDir, [baseName, '_line_drawing.png']);
    imwrite(img_LD, outputLineDrawing);
    
    % Step 3: Compute MAT
    MAT = computeMAT(img_LD, 28);
    
    overlayImg = imoverlay(rgb2gray(img_LD), MAT.skeleton, 'b');
    outputMATSkeleton = fullfile(outputDir, [baseName, '_MAT_skeleton_overlay.png']);
    imwrite(overlayImg, outputMATSkeleton);
    
    % Step 4: Compute contour and MAT-based properties
    vecLD = computeContourProperties(vecLD);
    [vecLD, MAT, ~] = computeAllMATfromVecLD(vecLD); 
    
    [MATcontourImages, MATskeletonImages, skeletalBranches] = ...
        computeAllMATproperties(MAT, img_LD, propertiesToCompute);

    % Step 5: Visualize and save property maps
    for p = 1:length(propertiesToCompute)
        prop = propertiesToCompute{p};

        % Use explicit figure handle instead of gcf
        figHandle = figure('Visible','off');
        
        new_drawSplitMATproperty(vecLD, prop);
        
        % Remove all axis decorations
        axis off;  % Turns off axes, ticks, labels
        set(gca, 'Position', [0 0 1 1]); % Make the plotted content fill the entire figure
        
        % Remove figure background so that only the plotted content remains
        set(figHandle, 'Color', 'none'); 
        
        outputPropFig = fullfile(outputDir, [baseName, '_', prop, '_score.png']);
        saveas(figHandle, outputPropFig);
        close(figHandle);
    end
    
    outputLDStruct = fullfile(outputDir, [baseName, '_scoredContours.mat']);
    save(outputLDStruct, 'vecLD', 'MAT', 'MATcontourImages', 'MATskeletonImages', 'skeletalBranches');
    
 
end
