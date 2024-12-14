% This script processes all line drawings in the folder:
% dataset/LD_dataset/new_val/beaches
% For each line drawing, it:
% 1. Vectorizes the line drawing
% 2. Renders it as an image
% 3. Computes the MAT
% 4. Computes contour and MAT-based properties
% 5. Maps these properties back to contours
% 6. Saves the results

% Ensure the required toolbox functions are on the MATLAB path
addpath(genpath('.'));

% Specify the input directory
inputDir = 'dataset/LD_dataset/val/beaches'; 
outputDir = 'dataset/LD_dataset/new_val/beaches'; 

% Get a list of images in the directory (adjust extensions as needed)
fileList = dir(fullfile(inputDir, '*.png')); % or *.png, *.tif depending on your data

% Specify the properties to compute (if empty, defaults are used)
propertiesToCompute = {'parallelism', 'separation', 'mirror', 'convexity', 'taper'};

for i = 1:length(fileList)
    fileName = fileList(i).name;
    inputFilePath = fullfile(inputDir, fileName);
    
    fprintf('Processing: %s\n', inputFilePath);
    
    % Step 1: Vectorize the line drawing
    vecLD = traceLineDrawingFromRGB(inputFilePath);
    
    % Step 2: Render line drawing as an image
    img_LD = renderLinedrawing(vecLD, []);
    
    % (Optional) Save the rendered line drawing
    [~, baseName, ~] = fileparts(fileName);
    outputLineDrawing = fullfile(inputDir, [baseName, '_line_drawing.png']);
    imwrite(img_LD, outputLineDrawing);
    
    % Step 3: Compute MAT
    % The second argument (28) is a scale parameter - adjust as needed
    MAT = computeMAT(img_LD, 28);
    
    % (Optional) Save a visualization of the MAT overlay
    overlayImg = imoverlay(rgb2gray(img_LD), MAT.skeleton, 'b');
    outputMATSkeleton = fullfile(inputDir, [baseName, '_MAT_skeleton_overlay.png']);
    imwrite(overlayImg, outputMATSkeleton);
    
    % Step 4: Compute contour properties and MAT-based properties
    vecLD = computeContourProperties(vecLD);
    [vecLD, MAT, ~] = computeAllMATfromVecLD(vecLD); 
    % Note: computeAllMATfromVecLD may internally call computeAllMATproperties 
    % and map results. Ensure your function pipeline is correct.
    
    % If you need specific scoring and direct mapping to contours:
    [MATcontourImages, MATskeletonImages, skeletalBranches] = ...
        computeAllMATproperties(MAT, img_LD, propertiesToCompute);

    % Step 5: Optionally visualize and save property maps
    % For each property, draw and save the result
    for p = 1:length(propertiesToCompute)
        prop = propertiesToCompute{p};
        
        % If drawMATproperty expects vecLD with properties fields:
        figure('Visible','off');
        drawMATproperty(vecLD, prop);
        title([prop, ' score'],'FontSize',18);
        
        outputPropFig = fullfile(inputDir, [baseName, '_', prop, '_score.png']);
        saveas(gcf, outputPropFig);
        close(gcf);
    end
    
    % At this point, vecLD should contain scored contours, and images saved.
    % If you want to save the updated vecLD structure (with fields 
    % containing the computed properties), you can do so as a MAT-file:
    outputLDStruct = fullfile(outputDir, [baseName, '_scoredContours.mat']);
    save(outputLDStruct, 'vecLD', 'MAT', 'MATcontourImages', 'MATskeletonImages', 'skeletalBranches');
end
