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

% binLocations is my x and counts is y values of the histogram
[count, binLocations] = imhist(message);

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

binaryImage = message < median;  % Values under 125 will be true (1)
figure
imshow(binaryImage)

%%
% Reading Processed Images Encrypted Message
% This script will run to decode a grayscale or BW image to deocde the
% message 

message = imread("frame 28.png");
% figure;
% subplot(1,2,1);
% imhist(message);
% subplot(1,2,2);
% imshow(message)

% binLocations is my x and counts is y values of the histogram
[count, binLocations] = imhist(message);

p = polyfit(binLocations, count, 2);

%x_range = 0:255;
%y_fit = polyval(p, x_range);


nLvls = 256; 
imgEq = eqHist(message, nLvls);

% figure
% subplot(2,2,1);
% imshow(message);
% title('Original Image');
% 
% subplot(2,2,2);
% histogram(message, nLvls);
% title('Original Histogram');
% 
% subplot(2,2,3);
% imshow(imgEq, []);
% title('Equalized Image');
% 
% subplot(2,2,4);
% histogram(imgEq, nLvls);
% title('Equalized Histogram');

figure;
imshow(imgEq)

% shading pattern?

hsize = [256, 256]; % Adjust kernel size based on the shading scale
sigma = 8;          % Adjust sigma to match the smoothness of the shading
h = fspecial('gaussian', hsize, sigma);

% Apply the filter to estimate the background shading
B = imfilter(imgEq, h);

% Convert to double for division operation
smoothImg = double(message);
B_double = double(B);

% Correct for shading by dividing original by the smoothed version
messageShade = smoothImg ./ B_double;

% Normalize and convert back to uint8
messageShade = mat2gray(messageShade);
messageShade = uint8(messageShade * 255);

% Display results
figure;
subplot(2,2,1);
imshow(imgEq);
title('Original Message');

subplot(2,2,2);
shading = uint8(mat2gray(B) * 255);
imshow(shading);
title('Estimated Shading Pattern');

subplot(2,2,3);
imshow(messageShade);
title('Shading-Corrected Message');

subplot(2,2,4);
imhist(messageShade);
title('Corrected Histogram');


%%
% We need to look at the image and figure out the histogram 

% Method 2: Manual min-max stretching
% Find current min and max values
min_val = double(min(message(:)));
max_val = double(max(message(:)));

% Create stretched image by scaling to full range [0,255]
stretched_img2 = uint8(255 * (double(message) - min_val) / (max_val - min_val));
%figure
%subplot(1,2,1), imshow(stretched_img2), title('Min-Max Stretched');
%subplot(1,2,2), imhist(stretched_img2)

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
median = median 
disp(['Median intensity from histogram: ', num2str(median)]);

% figure;
% plot(binLocations, count)
% hold on;
% plot(x_range,y_fit)
% hold on;
% xline(median)

% for values under the median, make black 1, values above make white 0
% look at count and threshold the values under 125 

binaryImage = stretched_img2 < median;  % Values under 125 will be true (1)
figure
imshow(binaryImage)




%%
BW=imbinarize(stretched_img2);
figure
imshow(BW)