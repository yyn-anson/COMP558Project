% Ensure the required toolbox functions are on the MATLAB path
addpath(genpath('.'));

% Define the categories (subfolders)
categories = {'beaches', 'city', 'forests', 'mountains', 'highways', 'offices'};

% Base directories
inputBaseDir = 'dataset/LD_dataset/val';
outputBaseDir = 'dataset/LD_dataset/new_val';

% Create output base directory if it doesn't exist
if ~exist(outputBaseDir, 'dir')
    mkdir(outputBaseDir);
end

% Properties to compute
propertiesToCompute = {'parallelism', 'separation', 'mirror', 'convexity', 'taper'};

% Initialize parallel pool if not already started
pool = gcp('nocreate');
if isempty(pool)
    parpool;  % Adjust number of workers if needed
end

% Attempt to select a GPU device (if available)
try
    gpuDevice(1);
    fprintf('GPU device selected successfully.\n');
catch
    warning('No GPU device found or failed to initialize. Computations will run on CPU.');
end

% Overall progress
totalCategories = length(categories);
for c = 1:totalCategories
    category = categories{c};

    % Input and output directories for this category
    inputDir = fullfile(inputBaseDir, category);
    outputDir = fullfile(outputBaseDir, category);

    % Create output directory if it does not exist
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Get a list of images for this category
    fileList = dir(fullfile(inputDir, '*.png'));
    numImages = length(fileList);

    fprintf('Starting category "%s" with %d images.\n', category, numImages);

    % Process images in parallel
    parfor i = 1:numImages
        try
            fileName = fileList(i).name;
            inputFilePath = fullfile(inputDir, fileName);

            workerID = 0;
            taskObj = getCurrentTask();
            if ~isempty(taskObj)
                workerID = taskObj.ID;
            end

            fprintf('Worker %d: Starting image %d/%d in category "%s": %s\n', ...
                workerID, i, numImages, category, inputFilePath);

            % Step 1: Vectorize the line drawing
            stepTic = tic;
            im = imread(inputFilePath);
            if size(im,3) == 3
                im = rgb2gray(im);
            end

            % Attempt to use GPU if possible
            try
                imGPU = gpuArray(im);
                imGPU3 = cat(3, imGPU, imGPU, imGPU);
                imRGB = gather(imGPU3);
            catch
                imRGB = cat(3, im, im, im);
            end

            % Temporary file for vectorization
            tempFile = fullfile(tempdir, sprintf('temp_line_drawing_%d_%s.png', i, category));
            imwrite(imRGB, tempFile);

            fprintf('Worker %d: Vectorizing line drawing...\n', workerID);
            vecLD = traceLineDrawingFromRGB(tempFile);
            fprintf('Worker %d: Vectorization completed in %.2f seconds.\n', workerID, toc(stepTic));

            % Step 2: Render line drawing as an image
            stepTic = tic;
            img_LD = renderLinedrawing(vecLD, []);
            [~, baseName, ~] = fileparts(fileName);
            outputLineDrawing = fullfile(outputDir, [baseName, '_line_drawing.png']);
            fprintf('Worker %d: Rendered line drawing in %.2f seconds.\n', workerID, toc(stepTic));

            % Step 3: Compute MAT
            stepTic = tic;
            fprintf('Worker %d: Computing MAT...\n', workerID);
            try
                img_LD_GPU = gpuArray(img_LD);
                MAT = computeMAT(img_LD_GPU, 28);
                MAT = gather(MAT);
            catch
                MAT = computeMAT(img_LD, 28);
            end
            fprintf('Worker %d: MAT computed in %.2f seconds.\n', workerID, toc(stepTic));

            overlayImg = imoverlay(rgb2gray(img_LD), MAT.skeleton, 'b');
            outputMATSkeleton = fullfile(outputDir, [baseName, '_MAT_skeleton_overlay.png']);

            % Step 4: Compute contour and MAT-based properties
            stepTic = tic;
            fprintf('Worker %d: Computing contour properties...\n', workerID);
            vecLD = computeContourProperties(vecLD);

            fprintf('Worker %d: Computing all MAT from VecLD...\n', workerID);
            [vecLD, MAT, ~] = computeAllMATfromVecLD(vecLD);

            fprintf('Worker %d: Computing all MAT properties...\n', workerID);
            [MATcontourImages, MATskeletonImages, skeletalBranches] = ...
                computeAllMATproperties(MAT, img_LD, propertiesToCompute);

            fprintf('Worker %d: Property computation done in %.2f seconds.\n', workerID, toc(stepTic));

            % Step 5: Visualize and save property maps
            stepTic = tic;
            fprintf('Worker %d: Visualizing and saving properties...\n', workerID);
            workerTempDir = fullfile(tempdir, sprintf('worker_%d_%s', workerID, category));
            if ~exist(workerTempDir, 'dir')
                mkdir(workerTempDir);
            end
            oldDir = cd(workerTempDir);

            for p = 1:length(propertiesToCompute)
                prop = propertiesToCompute{p};
                new_drawSplitMATproperty(vecLD, prop);

                % Rename and move generated images
                movefile([prop, '_bot50.png'], fullfile(outputDir, [baseName, '_', prop, '_bot50.png']));
                movefile([prop, '_top50.png'], fullfile(outputDir, [baseName, '_', prop, '_top50.png']));
                movefile([prop, '_intact.png'], fullfile(outputDir, [baseName, '_', prop, '_intact.png']));
            end

            cd(oldDir);
            fprintf('Worker %d: Visualization and file saving completed in %.2f seconds.\n', workerID, toc(stepTic));

            fprintf('Worker %d: Completed processing %s.\n', workerID, inputFilePath);

        catch ME
            fprintf('Worker %d: Error processing file %s: %s\n', workerID, inputFilePath, ME.message);
        end
    end

    fprintf('Completed category "%s".\n', category);
end

fprintf('All categories processed.\n');