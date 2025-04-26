import cv2
import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import gaussian_filter1d
import os
import glob

def analyze_occ_image(image_path, column=None, exposure_time_ms=33.0, show_plot=True):
    """
    Analyze blooming stripe pattern in OCC image and estimate bit rate.

    Args:
        image_path: Path to the input image.
        column: Column index or range (tuple) to extract signal from.
        exposure_time_ms: Frame exposure time in milliseconds (default = 33ms for ~30fps).
        show_plot: Whether to display the signal and binary plots.

    Returns:
        bits (list of 0s and 1s), bit_rate (estimated), signal profile (1D array)
    """
    
    
    
    # Load image
    img = cv2.imread(image_path)
    if img is None:
        print(f"Failed to load {image_path}")
        return [], 0, []

    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Extract the signal from a vertical slice (column range or middle)
    if isinstance(column, tuple):  # Range of columns (e.g. (200,210))
        signal = np.mean(gray[:, column[0]:column[1]], axis=1)  # Average across selected columns
    elif isinstance(column, int):  # Single column
        signal = gray[:, column]
    else:  # Default: middle 10 pixels
        mid = gray.shape[1] // 2
        signal = np.mean(gray[:, mid-5:mid+5], axis=1)

    # Smooth the signal to reduce noise
    signal_smooth = gaussian_filter1d(signal, sigma=2)

    # Normalize the signal to 0–1 range
    signal_norm = (signal_smooth - np.min(signal_smooth)) / (np.max(signal_smooth) - np.min(signal_smooth))

    # Threshold to binary (0 or 1) using 0.5 cutoff
    binary = (signal_norm > 0.5).astype(int)

    # Count transitions (1 to 0 or 0 to 1)
    transitions = np.sum(np.abs(np.diff(binary)))

    # Each two transitions represent one full bit (up + down)
    bit_count = transitions // 2

    # Calculate bit rate (bits per second)
    bit_rate = bit_count / (exposure_time_ms / 1000.0)

    # Plot results if enabled
    if show_plot:
        plt.figure(figsize=(10, 4))
        plt.plot(signal_norm, label='Normalized Signal')  # Plot the smoothed, normalized signal
        plt.plot(binary, label='Binary')  # Plot the binary thresholded version
        plt.title(f"{os.path.basename(image_path)} — Bitrate: {bit_rate:.2f} bps")
        plt.xlabel("Row (time axis)")
        plt.ylabel("Intensity")
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.show()

    # Return binary data, bitrate, and the signal
    return binary, bit_rate, signal_norm

# 🗂 Analyze up to 10 images in the folder
image_folder = r"Prototyping/sample packets"

# Collect all .jpg and .png files in the folder
image_files = glob.glob(os.path.join(image_folder, "*.jpg")) + glob.glob(os.path.join(image_folder, "*.png"))

# Limit analysis to first 10 images
max_images = 10

# Loop through each image
for idx, image_path in enumerate(image_files):
    if idx >= max_images:
        break  # Stop after 10 images
    print(f"\nAnalyzing {os.path.basename(image_path)} (Image {idx+1}/{max_images})...")
    bits, bitrate, _ = analyze_occ_image(image_path, column=(200, 210), exposure_time_ms=33.0, show_plot=True)
    print("Bits:", bits)
    print("Estimated Bitrate:", bitrate, "bps")
