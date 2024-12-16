%% RUN AFTER PROCESS_LD_DATASET_VAL.m
%% This computes the concatenated images where each score is a different channel
%% Note that R and G are swapped, since the way grayscaling works, 
% =~ 0.6 of the weight is G, =~ 0.3 is R, and =~ is B
% But our plots put G as intermediate and R as intense, so we need more R
% weight


% Specify the output directory where the scored images are located
outputDir = 'dataset/LD_dataset/new_val/offices'; 

% Get the list of files in the directory
fileList = dir(fullfile(outputDir, '*_convexity_score.png'));

for i = 1:length(fileList)
    % Extract the base name of the file (without suffix and extension)
    [~, baseName, ~] = fileparts(fileList(i).name);
    baseName = erase(baseName, '_convexity_score'); % Remove property suffix

    % Define paths for the required property images
    convexityImgPath = fullfile(outputDir, [baseName, '_convexity_score.png']);
    taperImgPath = fullfile(outputDir, [baseName, '_taper_score.png']);
    separationImgPath = fullfile(outputDir, [baseName, '_separation_score.png']);
    parallelismImgPath = fullfile(outputDir, [baseName, '_parallelism_score.png']);
    mirrorImgPath = fullfile(outputDir, [baseName, '_mirror_score.png']);

    % Check that all required images exist
    if ~isfile(convexityImgPath) || ~isfile(taperImgPath) || ...
       ~isfile(separationImgPath) || ~isfile(parallelismImgPath)
        fprintf('Skipping %s: Missing one or more property images.\n', baseName);
        continue;
    end

    % Read the property images
    convexityImg = imread(convexityImgPath);
    taperImg = imread(taperImgPath);
    separationImg = imread(separationImgPath);
    parallelismImg = imread(parallelismImgPath);
    mirrorImg = imread(mirrorImgPath);

    % Swap R and G channels for the specified images
    convexityImg = swapRGChannels(convexityImg);
    taperImg = swapRGChannels(taperImg);
    separationImg = swapRGChannels(separationImg);
    parallelismImg = swapRGChannels(parallelismImg);
    mirrorImg = swapRGChannels(mirrorImg);


    % Ensure grayscale
    convexityGray = ensureGray(convexityImg);
    taperGray = ensureGray(taperImg);
    separationGray = ensureGray(separationImg);
    parallelismGray = ensureGray(parallelismImg);
    mirrorGray = ensureGray(mirrorImg);

    % Create concatenated images
    concatenatedImg = cat(3, convexityGray, mirrorGray, parallelismGray);
    concatenatedImg2 = cat(3, convexityGray, taperGray, separationGray);
    concatenatedImg3 = cat(3, convexityGray, parallelismGray, separationGray);

    % Save the concatenated images
    outputConcatImg = fullfile(outputDir, [baseName, '_convexity_mirror_parallelism_concat.png']);
    outputConcatImg2 = fullfile(outputDir, [baseName, '_convexity_taper_separation_concat.png']);
    outputConcatImg3 = fullfile(outputDir, [baseName, '_convexity_parallelism_separation_concat.png']);
    imwrite(concatenatedImg, outputConcatImg);
    imwrite(concatenatedImg2, outputConcatImg2);
    imwrite(concatenatedImg3, outputConcatImg3);

    fprintf('Saved concatenated images for %s\n', baseName);
end

% Helper function to ensure grayscale
function grayImg = ensureGray(img)
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
end

% Helper function to swap R and G channels
function swappedImg = swapRGChannels(img)
    if size(img, 3) == 3
        % Swap the first and second channels (R and G)
        temp = img(:,:,1);
        img(:,:,1) = img(:,:,2);
        img(:,:,2) = temp;
    end
    swappedImg = img;
end
