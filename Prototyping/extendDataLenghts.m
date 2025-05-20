
filterspec = {'*.jpg;*.tif;*.png;*.gif','All Image Files'};
[file,path] = uigetfile(filterspec);
imagefile = [path file];
roi_image = imread(imagefile);

% Gray scale the image if it is not already
if size(roi_image, 3) == 3
    roi_GS = im2gray(roi_image);
else
    roi_GS = roi_image;
end

roi_BW = imbinarize(roi_GS);
[height, width, ~] = size(roi_image); % image dimensions

% Middle coloumn - look at the middle coloumn for the values  and
% extrapolate - increaese the regiobn lenghts 
% You can adjust the column_width parameter to control how much of the middle to extract
column_width = round(width * 0.2); 
middle = round(width / 2);
start_col = max(1, middle - floor(column_width/2));
end_col = min(width, middle + floor(column_width/2));

middle_column_BW = roi_BW(:, start_col:end_col);

horizontal_profile = sum(middle_column_BW, 2);

% go through the middle coloumn image and define the regions
regions = horizontal_profile > 0;
region_changes = diff([0; regions; 0]);
region_starts = find(region_changes == 1);
region_ends = find(region_changes == -1) - 1;

% Extend each region horizontally to cover the full width
extended_regions = false(size(roi_BW)); % blank image to mask the region

for i = 1:length(region_starts)
    extended_regions(region_starts(i):region_ends(i), :) = true;
end
% this should createa a horiztional bar for each of the regions found and
% extend it

figure('Name', 'Original Processing');
subplot(2,2,1); imshow(roi_BW); title('Original Binary ROI');
subplot(2,2,2); imshow(middle_column_BW); title('Middle Column Extracted');
subplot(2,2,3); imshow(extended_regions); title('Extended Regions');

%%

% bwboundaries again  to trace boundaries and plot rectangles
[B, L] = bwboundaries(extended_regions, 'noholes');
figure('Name', 'Extended Regions with Boundaries');
imshow(extended_regions);
hold on;

% Plot boundaries
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1);
end

% Find the regions again and plot the rectangular regions
for k = 1:length(B)
    boundary = B{k};
    
    % Find the min and max of the rol and cols to label the regions
    min_row = min(boundary(:,1));
    max_row = max(boundary(:,1));
    min_col = min(boundary(:,2));
    max_col = max(boundary(:,2));
    
    % Draw rectangles for this certain region (as the code iterates through
    % i)
    rectangle('Position', [min_col, min_row, max_col-min_col, max_row-min_row], ...
        'EdgeColor', 'g', 'LineWidth', 2);
    
    % Add region number label
    text(min_col + (max_col-min_col)/2, min_row + (max_row-min_row)/2, num2str(k), ...
        'Color', 'blue', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end

