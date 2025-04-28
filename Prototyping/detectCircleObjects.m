% Finding the circle area ROI for fruther image processing
% detect circle objectcs -> mask -> segment -> prep image for processing

image = imread("2025-Sem1/Capstone A/MATLAB" + ...
    "/images/Test images 10kHz transmission/_DSF0187.JPG");

% grayscale and binarise the image
GS = im2gray(image);
BW = imbinarize(GS);
figure; 
subplot(1,3,1); imshow(image); title('OG')
subplot(1,3,2); imshow(GS); title('Grayscale')
subplot(1,3,3); imshow(BW); title('Binary') % prob not the best way

% Gamma correction


