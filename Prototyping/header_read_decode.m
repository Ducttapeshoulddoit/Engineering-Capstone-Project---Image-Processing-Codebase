clear; clc; close all;

% Load and convert the image to grayscale if needed
imagePath = 'save.png';  % Path to image file
img = imread(imagePath);
if size(img, 3) == 3
    img = rgb2gray(img);  % Convert to grayscale if RGB
end
img = double(img);  % Convert image to double precision for processing

% --- Parameters ---
whiteThresh = 200;        % Threshold to detect white pixels (used for header)
bitThresh = 128;          % Threshold to decide if a bit is 1 or 0
numHeaderBits = 24;       % Number of bits in header (used to estimate bit height)
minHeaderHeight = 24;     % Minimum pixel height of white block to consider as header

% --- Extract Center Column of Image ---
[imgHeight, imgWidth] = size(img);
centerCol = round(imgWidth / 2);  % Middle column of image
colData = img(:, centerCol);      % Extract vertical line of pixel values

% --- Find White Blocks in Center Column ---
isWhite = colData > whiteThresh;  % Logical vector of where column is white
d = diff([0; isWhite; 0]);        % Find transitions (0->1 and 1->0)
starts = find(d == 1);            % Indices where white block starts
ends = find(d == -1) - 1;         % Indices where white block ends
lengths = ends - starts + 1;      % Lengths of each white block

% --- First Header Detection ---
% Find first white block that is large enough to be the header
firstHeaderIdx = find(lengths >= minHeaderHeight, 1, 'first');
if isempty(firstHeaderIdx)
    error('No valid header found');
end

% Get start/end row of first header
headerStartRow = starts(firstHeaderIdx);
headerEndRow = ends(firstHeaderIdx);
headerHeight = headerEndRow - headerStartRow + 1;

% Estimate bit height from known header bit count
bitHeight = round(headerHeight / numHeaderBits);

% --- Determine Start of Bit Data ---
dataStartRow = headerEndRow + 1;

% --- Detect Second Header (End Marker) ---
% Look for next white block with similar height as first header
remainingStarts = starts(starts > dataStartRow);  % Only look after first header
remainingEnds = ends(ends > dataStartRow);
remainingLengths = remainingEnds - remainingStarts + 1;

% Allow for small variation in size when detecting second header
tolerance = 0.2;
expectedHeaderHeightRange = [headerHeight * (1 - tolerance), headerHeight * (1 + tolerance)];
secondIdx = find(remainingLengths >= expectedHeaderHeightRange(1) & ...
                 remainingLengths <= expectedHeaderHeightRange(2), 1, 'first');

if isempty(secondIdx)
    error('Second header (end marker) not found.');
end

% Second header boundaries
endHeaderStart = remainingStarts(secondIdx);
endHeaderEnd = remainingEnds(secondIdx);

% --- Decode Bits Between Headers ---
bitRegionHeight = endHeaderStart - dataStartRow;       % Vertical space for bits
numBits = floor(bitRegionHeight / bitHeight);          % How many bits fit in that space

bitArray = zeros(1, numBits);        % Store decoded bits
rowStartList = zeros(1, numBits);    % Store start row of each bit
rowEndList = zeros(1, numBits);      % Store end row of each bit

for i = 1:numBits
    rStart = dataStartRow + (i-1)*bitHeight;
    rEnd = min(rStart + bitHeight - 1, imgHeight);  % Ensure it doesn't exceed image
    segment = colData(rStart:rEnd);                 % Segment of pixels for this bit
    avg = mean(segment);                            % Average pixel intensity
    bitArray(i) = avg > bitThresh;                  % Threshold to determine 0 or 1
    rowStartList(i) = rStart;
    rowEndList(i) = rEnd;
end

% --- Convert Bit Array to String ---
bitString = num2str(bitArray);          % Convert to character array with spaces
bitString(bitString == ' ') = '';       % Remove spaces to get full binary string
disp(['Decoded Bit String: ' bitString]);

% --- Visualize Decoded Bits on Image ---
figure;
imshow(uint8(img)); hold on;
title('Decoded Bits Overlay');

for i = 1:numBits
    y1 = rowStartList(i);
    y2 = rowEndList(i);
    x1 = centerCol - 5;
    x2 = centerCol + 5;

    color = bitArray(i) == 1;  % Red if bit = 1, black if bit = 0
    patch([x1 x2 x2 x1], [y1 y1 y2 y2], color*[1 0 0], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.3);  % Transparent rectangle
    
    text(centerCol + 8, (y1 + y2)/2, num2str(bitArray(i)), ...
        'Color', color*[1 0 0], 'FontSize', 12, 'VerticalAlignment', 'middle');
end

% --- Annotate Headers in Plot ---
line([1 imgWidth], [headerStartRow headerStartRow], ...
    'Color', 'blue', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, headerStartRow - 10, 'Header Start', 'Color', 'blue');

line([1 imgWidth], [headerEndRow headerEndRow], ...
    'Color', 'blue', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, headerEndRow - 10, 'Header End', 'Color', 'blue');

line([1 imgWidth], [endHeaderStart endHeaderStart], ...
    'Color', 'green', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, endHeaderStart - 10, 'Second Header Start', 'Color', 'green');

line([1 imgWidth], [endHeaderEnd endHeaderEnd], ...
    'Color', 'green', 'LineStyle', '--', 'LineWidth', 1.5);
text(5, endHeaderEnd - 10, 'Second Header End', 'Color', 'green');

% --- Output Bit-to-Pixel Ratio ---
bitToPixelRatio = headerHeight / numHeaderBits;
disp(['Bit-to-Pixel Ratio: ' num2str(bitToPixelRatio)]);
