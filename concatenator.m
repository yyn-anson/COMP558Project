% Define categories (subfolders)
categories = {'beaches', 'city', 'forests', 'mountains', 'highways', 'offices'};

% Base directories
valBaseDir = 'dataset/LD_dataset/val';
newValBaseDir = 'dataset/LD_dataset/new_val';

% Ensure output directories exist
for c = 1:length(categories)
    catDir = fullfile(newValBaseDir, categories{c});
    if ~exist(catDir, 'dir')
        mkdir(catDir);
    end
end

% Define properties and combinations for testing
properties = {'mirror','separation','parallelism','taper','convexity'};
combos = {
    {'convexity', 'mirror', 'taper'}
    {'convexity', 'mirror', 'parallelism'}
    {'convexity', 'taper', 'parallelism'}
    {'convexity', 'taper', 'separation'}
    {'convexity', 'parallelism', 'separation'}
    {'parallelism', 'taper', 'separation'}
    {'separation', 'mirror', 'parallelism'}
    {'taper', 'mirror', 'parallelism'}
    {'contour', 'contour', 'contour'} % special case using line drawing
};

% Function to process images (swap R/G, convert to grayscale)
swapAndGray = @(img) rgb2gray(img(:,:,[2 1 3])); 
% Explanation: img(:,:,[2 1 3]) swaps channels 1 and 2 (R <-> G), 
% then rgb2gray converts to grayscale.

for c = 1:length(categories)
    category = categories{c};
    inputDirVal = fullfile(valBaseDir, category);
    outputDirVal = fullfile(newValBaseDir, category);

    % Get a list of original images (a.png) in val directory
    fileList = dir(fullfile(inputDirVal, '*.png'));
    for i = 1:length(fileList)
        fileName = fileList(i).name;
        [~, baseName, ~] = fileparts(fileName);

        % Locate corresponding images in new_val
        % Properties: we look for <baseName>_<property>_score_top50.png and _bot50.png
        contourPath = fullfile(outputDirVal, [baseName, '_line_drawing.png']);
        if ~exist(contourPath, 'file')
            % If no line drawing found, skip
            continue;
        end

        % Check all property images exist
        propPaths_top50 = struct();
        propPaths_bot50 = struct();
        for p = 1:length(properties)
            prop = properties{p};
            top50Path = fullfile(outputDirVal, [baseName, '_', prop, '_score_top50.png']);
            bot50Path = fullfile(outputDirVal, [baseName, '_', prop, '_score_bot50.png']);
            if ~exist(top50Path, 'file') || ~exist(bot50Path, 'file')
                % If any property map doesn't exist, skip this image
                continue;
            end
            propPaths_top50.(prop) = top50Path;
            propPaths_bot50.(prop) = bot50Path;
        end

        % Read contour image
        contourImg = imread(contourPath);
        % Ensure contour is 3-channel for consistency
        if size(contourImg,3) == 1
            contourImg = cat(3, contourImg, contourImg, contourImg);
        end

        % Process each combination
        for comboIdx = 1:length(combos)
            comboProps = combos{comboIdx};
            
            if all(strcmpi(comboProps, 'contour'))
                % Special case: Contour, Contour, Contour
                % Process contour image
                grayContour = swapAndGray(contourImg);
                % Three identical gray channels
                finalImg = cat(3, grayContour, grayContour, grayContour);
                outputFile = fullfile(outputDirVal, [baseName, '_contour_concat.png']);
                imwrite(finalImg, outputFile);
            else
                % For property-based combos, we create both top50 and bot50 versions
                % Each channel from the corresponding property image
                for versionType = {'top50','bot50'}
                    vType = versionType{1}; % 'top50' or 'bot50'
                    
                    channelImgs = cell(1,3);
                    validCombo = true;
                    for ch = 1:3
                        prop = comboProps{ch};
                        if ~isfield(propPaths_top50, prop)
                            validCombo = false;
                            break;
                        end

                        if strcmp(vType, 'top50')
                            imgPath = propPaths_top50.(prop);
                        else
                            imgPath = propPaths_bot50.(prop);
                        end

                        if ~exist(imgPath, 'file')
                            validCombo = false;
                            break;
                        end
                        
                        inImg = imread(imgPath);
                        % Ensure 3-channel (some property images might be grayscale)
                        if size(inImg,3) == 1
                            inImg = cat(3, inImg, inImg, inImg);
                        end
                        grayImg = swapAndGray(inImg); 
                        channelImgs{ch} = grayImg;
                    end

                    if ~validCombo
                        continue; % skip this combo if any property missing
                    end

                    % Concatenate three grayscale images into a single 3-channel image
                    finalImg = cat(3, channelImgs{1}, channelImgs{2}, channelImgs{3});
                    
                    % Output file name:
                    outputFile = fullfile(outputDirVal, ...
                        [baseName, '_', vType, '_concat.png']);
                    imwrite(finalImg, outputFile);
                end
            end
        end
    end
end
