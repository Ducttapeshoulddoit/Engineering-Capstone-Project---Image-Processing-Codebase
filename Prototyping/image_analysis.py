import cv2
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from skimage import io, color, measure, filters, morphology
from skimage.measure import label, regionprops
from skimage.segmentation import clear_border, watershed
from skimage.feature import peak_local_max
from scipy import ndimage as ndi
from matplotlib.colors import ListedColormap

import tkinter as tk
from tkinter import filedialog


root = tk.Tk()
root.withdraw()

# Open file dialog
file_path = filedialog.askopenfilename(
    title="Select an image file",
    filetypes=[("Image files", "*.jpg *.jpeg *.png *.gif *.bmp *.tiff"), ("All files", "*.*")]
)

# Print selected file path
if file_path:
    print("Selected file:", file_path)
else:
    print("No file selected.")

# Read the image
image_path = file_path  # Replace with your image path
image_bgr = cv2.imread(image_path)
image = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Print image shapes
print("Captured image shape:", image.shape)
print("Grayscale image shape:", gray.shape)

# Apply Otsu's thresholding
ret, binary_cv = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
print("Binary image shape:", binary_cv.shape)

# Alternative Otsu threshold calculation using skimage
threshold_value = filters.threshold_otsu(gray)  # Compute Otsu's global threshold
binary = gray > threshold_value                 # Apply threshold to get binary mask

# Plot all three images side by side
fig, axs = plt.subplots(1, 3, figsize=(15, 5))
# Original image
axs[0].imshow(image)
axs[0].set_title('Original Image')
axs[0].axis('off')
# Grayscale image
axs[1].imshow(gray, cmap='gray')
axs[1].set_title('Grayscale Image')
axs[1].axis('off')
# Binary image
axs[2].imshow(binary, cmap='gray')
axs[2].set_title(f'Binary Image (Otsu Threshold = {ret:.0f})')
axs[2].axis('off')
plt.tight_layout()
plt.show()

# Plot the histogram
plt.figure(figsize=(8, 4))
plt.hist(gray.ravel(), bins=256, range=(0, 255))
plt.axvline(ret, color='red', linestyle='--', label=f'Otsu Threshold = {ret}')
plt.title('Grayscale Intensity Histogram with Otsu Threshold')
plt.xlabel('Pixel Intensity (0–255)')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True)
plt.show()

# Clean up binary image
cleaned = morphology.remove_small_objects(binary, min_size=1000)
cleaned = clear_border(cleaned)

# Label connected regions
label_image = measure.label(cleaned)

# Measure properties of labeled regions
props = measure.regionprops(label_image)

# Initialize with extreme values for global bounding box
min_row = np.inf
max_row = 0
min_col = np.inf
max_col = 0

# Visualize and print region properties
fig, ax = plt.subplots(figsize=(10, 6))
ax.imshow(binary, cmap='gray')

for region in props:
    if region.area >= 100:  # Ignore small areas
        # Get region bounding box
        minr, minc, maxr, maxc = region.bbox
        
        # Update global bounding box
        min_row = min(min_row, minr)
        max_row = max(max_row, maxr)
        min_col = min(min_col, minc)
        max_col = max(max_col, maxc)
        
        # Draw region bounding box
        rect = plt.Rectangle((minc, minr), maxc - minc, maxr - minr,
                          edgecolor='red', facecolor='none', linewidth=2)
        ax.add_patch(rect)
        ax.text(minc, minr - 5, f'ID: {region.label}', color='yellow', fontsize=8)
        
        # Print region properties
        print(f'Region {region.label}:')
        print(f' - Area: {region.area}')
        print(f' - Centroid: {region.centroid}')
        print(f' - Bounding box: {region.bbox}')
        print(f' - Eccentricity: {region.eccentricity}')
        print(f' - Solidity: {region.solidity}')
        print('---')

# Draw global bounding box
global_rect = plt.Rectangle((min_col, min_row), max_col - min_col, max_row - min_row,
                       edgecolor='green', facecolor='none', linewidth=3, linestyle='--')
ax.add_patch(global_rect)
ax.text(min_col, min_row - 15, 'Global ROI', color='green', fontsize=12, weight='bold')

ax.set_title('Regions with Individual (Red) and Global (Green) Bounding Boxes')
ax.set_axis_off()
plt.tight_layout()
plt.show()

# Save region properties to CSV
data = [{
    'Label': region.label,
    'Area': region.area,
    'Centroid Row': region.centroid[0],
    'Centroid Col': region.centroid[1],
    'Eccentricity': region.eccentricity,
    'Solidity': region.solidity,
    'BoundingBox': region.bbox
} for region in props if region.area >= 100]

df = pd.DataFrame(data)
df.to_csv('regionprops_report.csv', index=False)

# Add global bounding box information to the dataframe
global_roi = {
    'Label': 'Global ROI',
    'Area': (max_row - min_row) * (max_col - min_col),
    'Centroid Row': (min_row + max_row) / 2,
    'Centroid Col': (min_col + max_col) / 2,
    'BoundingBox': (min_row, min_col, max_row, max_col)
}
df_global = pd.DataFrame([global_roi])
df_global.to_csv('global_roi_report.csv', index=False)

# Show original and binary images with global bounding box
fig, axs = plt.subplots(1, 2, figsize=(12, 6))

# Original image with bounding box
axs[0].imshow(image)
axs[0].add_patch(plt.Rectangle((min_col, min_row), max_col-min_col, max_row-min_row,
                              edgecolor='g', facecolor='none', linewidth=2))
axs[0].set_title('Original with Global Bounding Box')
axs[0].axis('off')

# Binary image with bounding box
axs[1].imshow(binary, cmap='gray')
axs[1].add_patch(plt.Rectangle((min_col, min_row), max_col-min_col, max_row-min_row,
                              edgecolor='g', facecolor='none', linewidth=2))
axs[1].set_title('Binary with Global Bounding Box')
axs[1].axis('off')

plt.tight_layout()
plt.show()

# Create a mask for segmentation
mask = np.zeros_like(binary, dtype=np.uint8)
mask[int(min_row):int(max_row), int(min_col):int(max_col)] = 1

# Segment the images
segmented_original = image.copy()
for i in range(3):  # For RGB channels
    segmented_original[:,:,i] = segmented_original[:,:,i] * mask

segmented_gray = gray.copy() * mask
segmented_binary = binary.copy() * mask

# Display the segmentation results
fig, axs = plt.subplots(2, 2, figsize=(12, 10))

# Original image with bounding box
axs[0, 0].imshow(image)
axs[0, 0].add_patch(plt.Rectangle((min_col, min_row), max_col-min_col, max_row-min_row,
                                edgecolor='g', facecolor='none', linewidth=2))
axs[0, 0].set_title('Original Image')
axs[0, 0].axis('off')

# Mask
axs[0, 1].imshow(mask, cmap='gray')
axs[0, 1].set_title('Mask')
axs[0, 1].axis('off')

# Segmented original
axs[1, 0].imshow(segmented_original)
axs[1, 0].set_title('Segmented Original')
axs[1, 0].axis('off')

# Segmented grayscale
axs[1, 1].imshow(segmented_gray, cmap='gray')
axs[1, 1].set_title('Segmented Grayscale')
axs[1, 1].axis('off')

plt.tight_layout()
plt.show()

# Extract the ROI
roi_original = image[int(min_row):int(max_row), int(min_col):int(max_col)]
roi_gray = gray[int(min_row):int(max_row), int(min_col):int(max_col)]
roi_binary = binary[int(min_row):int(max_row), int(min_col):int(max_col)]

# Display the ROIs
fig, axs = plt.subplots(1, 3, figsize=(15, 5))

axs[0].imshow(roi_original)
axs[0].set_title('ROI - Original')
axs[0].axis('off')

axs[1].imshow(roi_gray, cmap='gray')
axs[1].set_title('ROI - Grayscale')
axs[1].axis('off')

axs[2].imshow(roi_binary, cmap='gray')
axs[2].set_title('ROI - Binary')
axs[2].axis('off')

plt.tight_layout()
plt.show()

# Save the ROI images
cv2.imwrite('roi_original.jpg', cv2.cvtColor(roi_original, cv2.COLOR_RGB2BGR))
cv2.imwrite('roi_gray.jpg', roi_gray)
cv2.imwrite('roi_binary.jpg', roi_binary.astype(np.uint8) * 255)

print(f"ROI extracted with dimensions: {roi_original.shape}")
print(f"ROI bounding box: Top-left=({min_col}, {min_row}), Bottom-right=({max_col}, {max_row})")

# Now that the ROI has been found, we can now decode

# First draw a line down the center of the image and read in the inputs
# find the centre of the image
width, height = roi_binary.shape[1], roi_binary.shape[0]
print(f"Width: {width}, Height: {height}")
centreX = width // 2

# Create a copy of the binary image for visualization
roi_binary_with_line = np.dstack([roi_binary.copy()*255]*3).astype(np.uint8)  # Convert binary to RGB for drawing colored line
roi_binary_with_line[:, centreX] = [0, 0, 255]  # Blue line for binary (converted to RGB)

# Extract the boolean pixel data along the center line
center_column_binary = roi_binary[:, centreX].copy()  # Boolean values (True/False)

# Display the binary image with center line
plt.figure(figsize=(10, 8))
plt.imshow(roi_binary_with_line)
plt.title('ROI - Binary with Center Line')
plt.axis('off')
plt.tight_layout()
plt.show()

# Plot the binary line profile
plt.figure(figsize=(10, 6))
plt.plot(range(height), center_column_binary.astype(int), 'b-', linewidth=2)
plt.title('Binary Pixel Values Along Center Line')
plt.xlabel('Y Position (pixels)')
plt.ylabel('Pixel Value (0 or 1)')
plt.grid(True)
plt.tight_layout()
plt.show()

# Find transitions (edges) in the binary data - the barcode format
transitions = np.where(np.diff(center_column_binary) != 0)[0]
print(f"Transitions found at positions: {transitions}")

# Save the boolean pixel data to CSV
line_data = pd.DataFrame({
    'Y_Position': range(height),
    'Binary_Value': center_column_binary.astype(int)
})
line_data.to_csv('center_line_binary_data.csv', index=False)

# Calculate segments either black or white (1 or 0)
segments = []
current_value = center_column_binary[0]
segment_start = 0

for i in range(1, len(center_column_binary)):
    if center_column_binary[i] != current_value:
        segments.append({
            'start': segment_start,
            'end': i - 1,
            'value': bool(current_value),
            'length': i - segment_start
        })
        current_value = center_column_binary[i]
        segment_start = i


segments.append({
    'start': segment_start,
    'end': len(center_column_binary) - 1,
    'value': bool(current_value),
    'length': len(center_column_binary) - segment_start
})

# go along the line and read out the outputs
print("\nSegments along center line:")
for i, segment in enumerate(segments):
    print(f"Segment {i+1}: Value={segment['value']}, Start={segment['start']}, End={segment['end']}, Length={segment['length']}")

# Save segment data to CSV
segment_data = pd.DataFrame(segments)
segment_data.to_csv('center_line_segments.csv', index=False)


