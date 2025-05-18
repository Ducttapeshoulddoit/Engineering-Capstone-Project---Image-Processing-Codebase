clear; clc; close all;


imagePath = 'roi_captured1.png';  % <<<< replace with your image file
img = imread(imagePath);
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = double(img);

% parameters
whiteThresh = 200;       % Threshold to detect white in center column
bitThresh = 128;         % Threshold to decide between 0 and 1
numHeaderBits = 24;      % Number of bits encoded in the header
minHeaderHeight = 24;    % Minimum height of white block to be considered header

% center col
[imgHeight, imgWidth] = size(img);
centerCol = round(imgWidth / 2);
colData = img(:, centerCol);

% find white block
isWhite = colData > whiteThresh;
d = diff([0; isWhite; 0]);  % Pad to detect transitions
starts = find(d == 1);
ends = find(d == -1) - 1;

% find first large white block with parameters
lengths = ends - starts + 1;
idx = find(lengths >= minHeaderHeight, 1, 'first');

if isempty(idx)
    error('No sufficiently large white block found.');
end

headerStartRow = starts(idx);
headerEndRow = ends(idx);
headerHeight = headerEndRow - headerStartRow + 1;
bitHeight = round(headerHeight / numHeaderBits);

% decode bits
startRow = headerEndRow + 1;
numBits = floor((imgHeight - startRow) / bitHeight); %determine bit ratio

bitArray = zeros(1, numBits);
rowStartList = zeros(1, numBits);
rowEndList = zeros(1, numBits);

for i = 1:numBits
    rStart = startRow + (i-1)*bitHeight;
    rEnd = min(rStart + bitHeight - 1, imgHeight);
    segment = colData(rStart:rEnd);
    avg = mean(segment);
    bitArray(i) = avg > bitThresh;
    rowStartList(i) = rStart;
    rowEndList(i) = rEnd;
end

% print bit string
bitString = num2str(bitArray);
bitString(bitString == ' ') = '';
disp(['Decoded Bit String: ' bitString]);

% plots for visualisation
figure;
imshow(uint8(img)); hold on;
title('Decoded Bits Overlay');

for i = 1:numBits
    y1 = rowStartList(i);
    y2 = rowEndList(i);
    x1 = centerCol - 5;
    x2 = centerCol + 5;

    % Color for plots: red for 1, black for 0
    if bitArray(i) == 1
        color = [1 0 0];
    else
        color = [0 0 0];
    end

    % Draw rectangle patch
    patch([x1 x2 x2 x1], [y1 y1 y2 y2], color, ...
        'EdgeColor', 'none', 'FaceAlpha', 0.3);

    % Label bit
    text(centerCol + 8, (y1 + y2)/2, num2str(bitArray(i)), ...
        'Color', color, 'FontSize', 12, 'VerticalAlignment', 'middle');
end

% --- Draw header bounds ---
line([1 imgWidth], [headerStartRow headerStartRow], ...
    'Color', 'blue', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, headerStartRow - 10, 'Header Start', 'Color', 'blue');

line([1 imgWidth], [headerEndRow headerEndRow], ...
    'Color', 'blue', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, headerEndRow - 10, 'Header End', 'Color', 'blue');

%bit to pixel ratio display
bitToPixelRatio = headerHeight / numHeaderBits;
disp(['Bit-to-Pixel Ratio: ' num2str(bitToPixelRatio)]);