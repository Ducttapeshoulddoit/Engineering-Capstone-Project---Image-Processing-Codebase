clear; clc; close all;

% --- Input Parameters ---
binaryStr = '0000100000010000000001110000110000111000000111111111110001100111100000110000';  % Your binary string
outputFile = 'generated_with_header.png'; 
imgWidth = 400; 
bitHeight = 30;  

numHeaderBits = 24;                 % Header size in bits
headerHeight = bitHeight * numHeaderBits;

bitArray = binaryStr - '0';        % Convert char array to numeric array
numBits = length(bitArray);

% --- Total Image Height includes:
% Header (top) + Data Bits + Header (bottom)
imgHeight = headerHeight + numBits * bitHeight + headerHeight;

% --- Initialize Image to All White (255) ---
img = ones(imgHeight, imgWidth) * 255;

% --- Encode Data Bits ---
for i = 1:numBits
    rStart = headerHeight + (i-1)*bitHeight + 1;
    rEnd = rStart + bitHeight - 1;
    if bitArray(i) == 0
        img(rStart:rEnd, :) = 0;  % Set to black for 0
    end
end

% --- Display and Save Image ---
figure;
imshow(uint8(img));
title('Binary Encoded Image with White Header (Top and Bottom)');

imwrite(uint8(img), outputFile);
fprintf('Image saved as %s\n', outputFile);
