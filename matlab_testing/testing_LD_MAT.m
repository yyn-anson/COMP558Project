%NOTE: have to run 'setup' file first

% Step 1 - Create Line Drawing %%%%%%%%%%%%%%%%%%%%
fileName = 'images/example.jpg';
vecLD = traceLineDrawingFromRGB(fileName);

% render as an image
img_LD = renderLinedrawing(vecLD, []);

imwrite(img_LD, 'line_drawing.png');

% Step 2 - Compute Medial Axis Transform (MAT) %%%%%%%%%%%%%%%%%%%%
MAT = computeMAT(img_LD, 28);


% Checkpoint - Visualizing Results %%%%%%%%%%%%%%%%%%%%
figure;
subplot(1,2,1);
imshow(img_LD);
title('Line Drawing Image');

subplot(1,2,2);
overlayImg = imoverlay(rgb2gray(img_LD), MAT.skeleton, 'b');
imshow(overlayImg);
title('MAT Skeleton');

imwrite(overlayImg, 'MAT_skeleton_overlay.png');


%Step 3 - MAT Properties & Contour Properties %%%%%%%%%%%%%%%%%%%%
%Seperate File for this, after running this one





