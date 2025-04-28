% Finding the circle area ROI for fruther image processing
% detect circle objectcs -> mask -> segment -> prep image for processing

image = imread("2025-Sem1/Capstone A/MATLAB" + ...
    "/images/Test images 10kHz transmission/_DSF0187.JPG");

% Check the image is linear or SRGB - maybe later

% grayscale and binarise the image
GS = im2gray(image);
BW = imbinarize(GS);
figure; 
subplot(1,3,1); imshow(image); title('OG')
subplot(1,3,2); imshow(GS); title('Grayscale')
subplot(1,3,3); imshow(BW); title('Binary') % prob not the best way

% Gamma correction
J = imadjust(GS,[],[],0.5);
figure; imshowpair(image,J,"montage")

%% New method - make 4 cursors that will trace across the image to find the
% circle object.

[widht, height] = size(J);

% make 4 cursors - h (horziontal) , v (vert) , d1/d2 (diagonal 1/2)
% D1 starts from 1,1 to the w,h while D2 starts from (w,1) to (1,h)

% making 1 first
