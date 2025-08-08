%% Semester 2 percentage change in stripe width VS modulation frequency

% First read in all the images from Brendan's captures and ROI them
% Rerrun this section if you want to analyse a select amount of images in a
% folder
filterspec = {'*.jpg;*.tif;*.png;*.gif','All Image Files'};
[file,path] = uigetfile(filterspec);

imagefile = [path file];
image = imread(imagefile);

%% Run this section if you want to read a whole folder of images
% Choose a folder - from GPT
folder = uigetdir([], 'Select folder with images');
if folder == 0
    error('No folder selected.');
end

% Define supported image extensions
extensions = {'*.jpg', '*.png', '*.tif', '*.gif'};

% Collect all image files in the folder
imageFiles = [];
for i = 1:length(extensions)
    imageFiles = [imageFiles; dir(fullfile(folder, extensions{i}))];
end

% Check if any images found
if isempty(imageFiles)
    error('No image files found in the selected folder.');
end

% Loop through each image file
for k = 1:length(imageFiles)
    filename = fullfile(folder, imageFiles(k).name);
    image = imread(filename);
    
    % figure
    % imshow(image);
    % title(['Image ' num2str(k) ': ' imageFiles(k).name]);
end

%% Now we loaded in all the images - GS->Binarise->RoI

% LPF Filter Specs
hsize = [500,500];
sigma = 1.2;
h = fspecial('gaussian',hsize,sigma);
roiStruct = {};

% Grayscale all the images - all images are in the imageFiles struct
for t = 1:length(imageFiles)
    % get the dir of the image to process it
    imagePath =  fullfile(folder,imageFiles(t).name);
    img = imread(imagePath);

    GS = im2gray(img);
    BW = imbinarize(GS);

    B = imfilter(BW,h); % filtering stuff out
  
    % returns an binary image whihc should have the edges - tested with
    % a variety of methods.
    BW1 = edge(B,'Canny',0.5);

    % Boundaries -> refer to detectCircleObjects.m for full documentation
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

    %
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
    
    title('Image with Boundaries and Bounding Box');

    % now segment the image
    mask = zeros(size(BW));  % Using BW size since we'll apply to binary image
    
    % make a array of image to mask
    mask(min_row:max_row, min_col:max_col) = 1;
    
    % Segment the original image using the mask
    if size(img, 3) == 3  % If it's an RGB image
        segmented_image = img;
        for i = 1:3
            segmented_image(:,:,i) = img(:,:,i) .* uint8(mask);
        end
    else  % If it's already grayscale
        segmented_image = img .* uint8(mask);
    end
    
    % Segment the binary image
    segmented_BW = BW .* mask;
    
    % Segment the grayscale image
    segmented_GS = GS .* uint8(mask);
    
    figure;
    subplot(1,2,1); imshow(img); title('Original Image');
    hold on;
    rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
             'EdgeColor', 'g', 'LineWidth', 2);
    hold off;


    subplot(1,2,2); imshow(mask); title('Mask');
    
    roi_image = segmented_image(min_row:max_row, min_col:max_col, :);
    roi_GS = segmented_GS(min_row:max_row, min_col:max_col);
    roi_BW = segmented_BW(min_row:max_row, min_col:max_col);
    
    % Extracted ROI
    figure;
    subplot(1,3,1); imshow(roi_image); title('ROI - Original');
    subplot(1,3,2); imshow(roi_GS); title('ROI - Grayscale');
    subplot(1,3,3); imshow(roi_BW); title('ROI - Binary');

    roiStruct{t} = roi_BW;

end

%% Now we can extract the data.
% now that we have extrcted the BW now we dan


