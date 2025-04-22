clear;
clc;
%%
% Reading Processed Images Encrypted Message
% This script will run to decode a grayscale or BW image to deocde the
% message 
close all
message = imread("frame 28.png");
figure;
subplot(1,2,1);
imhist(message);
subplot(1,2,2);
imshow(message)

% We need to look at the image and figure out the histogram 

% Method 2: Manual min-max stretching
% Find current min and max values
min_val = double(min(message(:)));
max_val = double(max(message(:)));

% Create stretched image by scaling to full range [0,255]
stretched_img2 = uint8(255 * (double(message) - min_val) / (max_val - min_val));
figure
subplot(1,2,1), imshow(stretched_img2), title('Min-Max Stretched');
subplot(1,2,2), imhist(stretched_img2)

% binLocations is my x and counts is y values of the histogram
[count, binLocations] = imhist(stretched_img2);

p = polyfit(binLocations, count, 2);

x_range = 0:255;
y_fit = polyval(p, x_range);


% Find the median to threshold the values

%cumsum - returns sum of count - our y values.  Add up the amount of pixels
%of the histogram/image then find the middle point 
cumsum_histogram = cumsum(count);
total_pixels = sum(count);
median_index = find(cumsum_histogram >= total_pixels/2, 1, 'first');
%jump to the median index found based on the binLocations/x values (0-256)
% look at x values/binLocations array to find the median value using the
% index found
median = binLocations(median_index);
disp(['Median intensity from histogram: ', num2str(median)]);

figure;
plot(binLocations, count)
hold on;
plot(x_range,y_fit)
hold on;
xline(median)

% for values under the median, make black 1, values above make white 0
% look at count and threshold the values under 125 

binaryImage = stretched_img2 < 125;  % Values under 125 will be true (1)
figure
imshow(binaryImage)




%%
BW=imbinarize(stretched_img2);
figure
imshow(BW)