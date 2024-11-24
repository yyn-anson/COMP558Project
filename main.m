% Step 1 - Create Line Drawing %%%%%%%%%%%%%%%%%%%%
fileName = 'images/example.jpg';
vecLD = traceLineDrawingFromRGB(fileName);

% render as an image
img_LD = renderLinedrawing(vecLD, []);

% Step 2 - Compute Medial Axis Transform (MAT) %%%%%%%%%%%%%%%%%%%%
MAT = computeMAT(img_LD, 28);

% Checkpoint - Visualizing Results %%%%%%%%%%%%%%%%%%%%
figure;
subplot(1,2,1);
imshow(img_LD);
title('Line Drawing Image');

subplot(1,2,2);
imshow(imoverlay(rgb2gray(img_LD), MAT.skeleton, 'b'));
title('MAT Skeleton');


%Step 3 - Retrieving Contour Properties %%%%%%%%%%%%%%%%%%%%


