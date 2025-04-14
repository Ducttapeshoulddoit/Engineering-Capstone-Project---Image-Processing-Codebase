"Picture -> ROI Detection ->  Signal Extraction and Normalisation"

"Start with reading in the image"
#import os, sys
#from PIL import Image
#import numpy as np

#im = Image.open("frame_633.png")
#print(im.format, im.size, im.mode)
#im.show()


import os
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from PIL import Image
import numpy as np
import time
import glob

def create_animation(folder_path, interval=100):
    # Get list of image files from the folder
    image_files = sorted(glob.glob(os.path.join(folder_path, "*.jpg")) + 
                         glob.glob(os.path.join(folder_path, "*.jpeg")) + 
                         glob.glob(os.path.join(folder_path, "*.png")))
    
    
    fig = plt.figure(figsize=(10, 8))
    plt.axis('off')  
    
    #  animation iteration - go to next image
    def update_frame(frame_number):
        plt.clf()  
        img = Image.open(image_files[frame_number % len(image_files)])
        plt.imshow(np.array(img))
        plt.axis('off')
        plt.title(f"Frame {frame_number+1}/{len(image_files)}")
        return plt,
    
    ani = animation.FuncAnimation(fig, update_frame, frames=len(image_files), 
                                  interval=interval, blit=False, repeat=True)
    
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    
    folder_path = "Prototyping/sample packets"
    frame_interval = 200
    
    create_animation(folder_path, frame_interval)