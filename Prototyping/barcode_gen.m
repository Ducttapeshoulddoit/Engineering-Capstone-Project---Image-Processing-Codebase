clear;clc;close all;

binaryStr = '01010101010101';  % your binary string
outputFile = 'generated_with_header.png'; 
imgWidth = 400; 
bitHeight = 30;  

numHeaderBits = 24; % header size
headerHeight = bitHeight * numHeaderBits;

bitArray = binaryStr - '0'; 
numBits = length(bitArray);


imgHeight = headerHeight + numBits * bitHeight;
img = ones(imgHeight, imgWidth) * 255;  


for i = 1:numBits
    rStart = headerHeight + (i-1)*bitHeight + 1;
    rEnd = rStart + bitHeight - 1;
    if bitArray(i) == 0
        img(rStart:rEnd, :) = 0;
    end
end

figure;
imshow(uint8(img));
title('Binary Encoded Image with 16-bit White Header');

imwrite(uint8(img), outputFile);
fprintf('Image saved as %s\n', outputFile);
