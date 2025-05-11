import cv2
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from skimage import io, color, measure, filters, morphology
from skimage.measure import label, regionprops
from skimage.segmentation import clear_border

# Read the image
image_bgr = cv2.imread('Prototyping/8000_2.jpg')  # Replace with your image path
image = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Apply Otsu's thresholding
ret, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

# Print image shapes
print("Captured image shape:", image.shape) 
print("Grayscale image shape:", gray.shape)
print("Binary image shape:", binary.shape)

# Alternative Otsu threshold calculation using skimage
threshold_value = filters.threshold_otsu(gray)  # Compute Otsu's global threshold
binary = gray > threshold_value                 # Apply threshold to get binary mask

# Plot all three images side by side
fig, axs = plt.subplots(1, 3, figsize=(15, 5))

# Original image
axs[0].imshow(image)
axs[0].set_title('Captured Image')
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

# Visualize and print region properties
fig, ax = plt.subplots(figsize=(10, 6))
ax.imshow(binary, cmap='gray')

for region in props:
    if region.area >= 100:  # Ignore small areas
        minr, minc, maxr, maxc = region.bbox
        rect = plt.Rectangle((minc, minr), maxc - minc, maxr - minr,
                             edgecolor='red', facecolor='none', linewidth=2)
        ax.add_patch(rect)
        ax.text(minc, minr - 5, f'ID: {region.label}', color='yellow', fontsize=8)
        print(f'Region {region.label}:')
        print(f' - Area: {region.area}')
        print(f' - Centroid: {region.centroid}')
        print(f' - Bounding box: {region.bbox}')
        print(f' - Eccentricity: {region.eccentricity}')
        print(f' - Solidity: {region.solidity}')
        print('---')

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