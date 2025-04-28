% Finding region on interest to segment

% Finding the circle area ROI for fruther image processing
% detect circle objectcs -> mask -> segment -> prep image for processing

% image = imread("2025-Sem1/Capstone A/MATLAB" + ...
%     "/images/Test images 10kHz transmission/_DSF0190.JPG");

 image = imread("2025-Sem1/Capstone A/MATLAB" + ...
     "/images/1kHz.jpg");

% Check the image is linear or SRGB - maybe later


% grayscale and binarise the image
GS = im2gray(image);
BW = imbinarize(GS);

figure; 
subplot(1,3,1); imshow(image); title('OG')
subplot(1,3,2); imshow(GS); title('Grayscale')
subplot(1,3,3); imshow(BW); title('Binary') % prob not the best wa

%% Applying an LPF filter to remove some noise from the image
fig4 = figure(4);
subplot(1,2,1);
imshow(BW);
title("Original Image");

hsize = [500,500];
sigma = 1.2;
h = fspecial('gaussian',hsize,sigma);

B = imfilter(BW,h); % filtering stuff out
subplot(1,2,2)
imshow(B)
title("After the LPF");

% returns an binary image whihc should have the edges - tested with
% a variety of methods.
BW1 = edge(B,'Canny',0.5);

figure()
imshow(BW1);
title("Edged detected image")

%% BWBOUNDARIES - traces the boundaries of objects  
[B,L] = bwboundaries(BW1);

figure;
imshow(BW1);
hold on;
title("Original Opened and Binary Image")

% Boundaries - from bwboundaries matlab documentation - outlines the
% regions found with red lines
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1)
end
title('Image with Boundaries');


% After your existing boundary plotting code, add this:
% Find the extreme points across ALL boundaries to form one bounding box

% Initialize with extreme values
min_row = inf;
max_row = 0;
min_col = inf;
max_col = 0;


for k = 1:length(B)
    boundary = B{k};
    
    % Update min/max values if this boundary has more extreme points
    min_row = min(min_row, min(boundary(:,1)));
    max_row = max(max_row, max(boundary(:,1)));
    min_col = min(min_col, min(boundary(:,2)));
    max_col = max(max_col, max(boundary(:,2)));
end

rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
          'EdgeColor', 'g', 'LineWidth', 2);

% Optional: Add a title to clarify what's being shown
title('Image with Boundaries and Bounding Box');

%%
figure; subplot (1,2,1); imshow(image)
rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
          'EdgeColor', 'g', 'LineWidth', 2);
hold on
subplot (1,2,2); imshow(BW)
rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
          'EdgeColor', 'g', 'LineWidth', 2);


%% now segment
mask = zeros(size(BW));  % Using BW size since we'll apply to binary image

% make a array of image to mask
mask(min_row:max_row, min_col:max_col) = 1;

% Segment the original image using the mask
if size(image, 3) == 3  % If it's an RGB image
    segmented_image = image;
    for i = 1:3
        segmented_image(:,:,i) = image(:,:,i) .* uint8(mask);
    end
else  % If it's already grayscale
    segmented_image = image .* uint8(mask);
end

% Segment the binary image
segmented_BW = BW .* mask;

% Segment the grayscale image
segmented_GS = GS .* uint8(mask);

figure;
subplot(2,2,1); imshow(image); title('Original Image');
hold on;
rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
         'EdgeColor', 'g', 'LineWidth', 2);
hold off;

subplot(2,2,2); imshow(mask); title('Mask');
subplot(2,2,3); imshow(segmented_image); title('Segmented Original');
subplot(2,2,4); imshow(segmented_GS); title('Segmented Grayscale');

roi_image = segmented_image(min_row:max_row, min_col:max_col, :);
roi_GS = segmented_GS(min_row:max_row, min_col:max_col);
roi_BW = segmented_BW(min_row:max_row, min_col:max_col);

% xtracted ROI
figure;
subplot(1,3,1); imshow(roi_image); title('ROI - Original');
subplot(1,3,2); imshow(roi_GS); title('ROI - Grayscale');
subplot(1,3,3); imshow(roi_BW); title('ROI - Binary');


