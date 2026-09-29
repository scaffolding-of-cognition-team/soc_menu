#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 21:59:51 2023

A realtime viewer for nifti files. This script will monitor a folder for new nifti files that are produced by the dicomFTP script. When a new file is detected, it will be loaded and displayed. The script will continue to monitor the folder for new files and will update the display accordingly.

This viewer will turn red when it estimates that the brain is outside of the field of view. This is done by checking the number of voxels in the middle slice that are above a threshold. If the number of voxels is more than expected, it will think there is brain outside. This is a heuristic that works well for our sequences but you may need to adjust this threshold for other scanners.

Log on to the CNI account (look at the wiki for the password under the page "Access CNI + Team Computer")
To use this script, first run dicomFTP from this repo (https://github.com/InstitutoDOr/scannerConverter):
cd ./scannerConverter 
./dicomFTP /cnimr/images/ # Or wherever your scanner is storing the dicoms

To test it, you can use Utils_simulate_realtime_fMRI.sh

@author: camronellis
"""

# Run the imports
import numpy as np
import matplotlib.pyplot as plt
import nibabel as nib
import os
import glob
import time
from datetime import datetime, timedelta

def find_trough(counts, vals, min_peak_dist=10):
    """
    Find the trough between the brain and non-brain voxels
    """
    # Find the peak of the brain voxels. Add a buffer at the start of the count and then find the next peak
    brain_peak = np.argmax(counts[min_peak_dist:]) + min_peak_dist

    # Find the peak of the non-brain voxels.
    non_brain_peak = np.argmax(counts[:brain_peak:])

    # Find the trough between the brain and non-brain peaks
    trough_idx = np.argmin(counts[non_brain_peak:brain_peak]) + non_brain_peak
    
    # Convert the trough into a number
    trough = vals[trough_idx]

    return trough

def delete_folder_if_old(folder_path):
    # Check if the folder exists
    if not os.path.exists(folder_path):
        print("The folder does not exist.")
        return

    # Get the creation time of the folder
    creation_time = os.path.getctime(folder_path)
    
    # Convert creation time to a datetime object
    creation_date = datetime.fromtimestamp(creation_time)

    # Calculate the difference between current time and folder creation time
    time_difference = current_time - creation_date

    # Check if the folder was created more than an hour ago
    if time_difference >= timedelta(hours=1):
        # Delete the folder
        try:
            os.system('echo rm -rf %s' % folder_path)
            print(f"The folder {folder_path} was created a while ago so it has been deleted.")
        except OSError as e:
            print(f"Error: {e}. The folder {folder_path} cannot be deleted.")

# Specify the folder in which dicomFTP will store the new nifti volume
input_dir = '/home/soc/scannerConverter/output_scans/'

# Check to see if there are files in this folder, if there are, delete them
folders = glob.glob('%s/series*/' % input_dir)

if len(folders) > 0:
    print('Checking if any of the folders are >1 hour old and can be deleted')
    for folder in folders:
        delete_folder_if_old(folder)

print('\n\nStarting real time viewer in %s.\n\nStop when finished' % input_dir)

# What size do you want the figure to be
fig_dim = [30, 30] 

# What proportion of voxels should be brain voxels in the middle slice? This is used to check whether the brain is outside of the FOV
non_brain_voxel_prop = 0.7

# What proportion of voxels should be the max you find on the first or last slice? This is used to check whether the brain is outside of the FOV
FOV_voxel_prop = [0.10, 1]

# Do you want to vertically flip the saggital scan?
vertical_flip_saggital=1

# Make a watermark to put in the corner of the image if the brain is outside of the FOV
watermark_dim = 20
watermark = np.ones((watermark_dim, watermark_dim))
watermark[np.eye(watermark_dim) == 1] = 0
watermark[np.fliplr(np.eye(watermark_dim)) == 1] = 0


# Preset
most_recent_file_time = 0
most_recent_dir = ''
TR_total = 0
fig = plt.figure()
while 1:
    
    # Reset each cycle
    series_files = []
    while len(series_files) == 0:
        
        # Find the most recent folder in the directory
        series_dirs = glob.glob(input_dir + '*')
        
        # Sort directory and flip order
        series_dirs.sort(key=lambda x: os.path.getmtime(x))
        series_dirs.reverse()
        
        # Find most recent directory (ignoring other files that might exist)
        file_counter = 0
        while file_counter < len(series_dirs):
            
            if os.path.isdir(series_dirs[file_counter]):
                recent_dir = series_dirs[file_counter]
                file_counter = len(series_dirs)
                continue
            file_counter += 1
            
        # If the folder has been newly created then reset the TR count
        if recent_dir != most_recent_dir:
            TR_total = 0
            
            # Update the most recent directory
            most_recent_dir = np.copy(recent_dir)
            
            print('\nChanging directory to %s' % recent_dir)
        
        # Find the most recent file in the directory
        series_files = glob.glob(recent_dir + '/*')
        
        if len(series_files) == 0:
            # Wait for a bit before looping again
            time.sleep(0.1)
    
    # Check if this folder has a file and take the one most recently created
    recent_file = max(series_files, key=os.path.getmtime)

    # When did this file get created?
    curr_file_time = os.path.getmtime(recent_file)

    # Check if this file is newer than the most recent file
    if curr_file_time > most_recent_file_time:

        # What is the most recent file time?
        most_recent_file_time = os.path.getmtime(recent_file)

        # Increment total TRs
        TR_total += 1

        # Resize the figure on every increment
        plt.rcParams['figure.figsize'] = fig_dim
        
    else:
            
        # Wait for a bit and then check again
        time.sleep(0.1)

        continue

    # Load the most recent file
    nii = nib.load(recent_file)
        
    # Extract the data from the nifti
    vol = nii.get_fdata()

    # For each slice of vol, show the image array
    plot_dim = int(np.ceil(np.sqrt(vol.shape[2])))
    
    # Get the middle slice of the brain and compute the number of voxels. This will help us know if we are outside of the FOV
    middle_slice = vol[:, :, int(vol.shape[2] / 2)]

    # Find the trough of the histogram between the two peaks (brain and non-brain)
    counts, middle_slice_bins = np.histogram(middle_slice.flatten(), bins=100)

    # Find the threshold for what counts as brain
    brain_thresh = find_trough(counts, middle_slice_bins)
    num_voxels = np.sum(middle_slice > brain_thresh) # Count the number of voxels that are above the threshold

    # What are the max number of voxels you should find in the first and last slice? This will help us know if we are outside of the FOV
    min_FOV_thresh = num_voxels * FOV_voxel_prop[0]
    max_FOV_thresh = num_voxels * FOV_voxel_prop[1]

    # Flatten the 3d volume into a patchwork of 2d images where each patch is a slice of the volume
    lightbox_slices = np.zeros((vol.shape[0] * plot_dim, vol.shape[1] * plot_dim))
    slice_counter = 0
    max_val = np.max(vol)
    FOV_warning = False
    for x_idx in range(plot_dim):
        for y_idx in range(plot_dim):
            
            # Increment until your run out of brain
            if slice_counter < vol.shape[2]:
                
                # Pull out the slice info
                slice_data = np.copy(vol[:, :, slice_counter])
                
            else:
                # Make the last cells blank
                slice_data = np.max(vol)
            
            num_voxel_slice = np.sum(slice_data > brain_thresh)
            
            # Check whether the brain is outside of the FOV
            if (num_voxel_slice > min_FOV_thresh and slice_counter == 0) or (num_voxel_slice > max_FOV_thresh and slice_counter == vol.shape[2] - 1):

                #print('WARNING: Brain might be outside of the FOV. Check!')
                FOV_warning = True

                # Put a watermark on the image
                slice_data[:watermark_dim, :watermark_dim] = watermark * max_val
                
            # Store the flattened slice
            lightbox_slices[x_idx * vol.shape[0]:(x_idx + 1) * vol.shape[0], y_idx * vol.shape[1]:(y_idx + 1) * vol.shape[1]] = slice_data
                
            slice_counter += 1
    
    # Provide saggital and coronal views so that you can see the whole brain shape
    other_views = np.zeros(lightbox_slices.shape)
    num_views = 2
    
    # Saggital views
    for saggital_idx in range(num_views): # Increment through cuts of the saggital view
        idx = int((saggital_idx + 1) * ((vol.shape[0] - 1) / (num_views + 1)))
        slice_data = np.squeeze(np.copy(vol[idx, :, :]))
        
        # Rotate the data
        slice_data = np.rot90(slice_data, 1)
        
        # Add a frame around the slice
        slice_data[:, 0] = max_val
        slice_data[0, :] = max_val        
        slice_data[:, -1] = max_val
        slice_data[-1, :] = max_val
        
        # Insert this view into the array
        other_views[0:slice_data.shape[0], saggital_idx * slice_data.shape[1]:(saggital_idx + 1) * slice_data.shape[1]] = slice_data
    
    # Coronal views
    for coronal_idx in range(num_views): # Increment through cuts
        idx = int((coronal_idx + 1) * ((vol.shape[1] - 1) / (num_views + 1)))
        slice_data = np.squeeze(np.copy(vol[:, idx, :]))

        # Rotate the data
        slice_data = np.rot90(slice_data, 1)
        
        # Add a frame around the slice
        slice_data[:, 0] = max_val
        slice_data[0, :] = max_val        
        slice_data[:, -1] = max_val
        slice_data[-1, :] = max_val     

        # Insert this view into the array
        other_views[slice_data.shape[0]:slice_data.shape[0] * 2, coronal_idx * slice_data.shape[1]:(coronal_idx + 1) * slice_data.shape[1]] = slice_data

    # Trim the other views
    other_views = other_views[:slice_data.shape[0] * 2, :(coronal_idx + 1) * slice_data.shape[1]]
    
    # If the brain is outside of the field of view then show it red
    if FOV_warning == True:
        cmap='Reds'
    else:
        cmap='gray'
    
    # If we need to rotate the saggital view, do so here
    if vertical_flip_saggital == 1:
        other_views = np.rot90(other_views, 2)
    
    # Make the plots of the data and clean it up
    plt.subplot(1, 2, 1)
    plt.imshow(lightbox_slices, cmap=cmap)
    plt.axis('off')
    plt.title('Real-time viewer. Total TRs: %d' % TR_total, fontsize=20)
    
    plt.subplot(1, 2, 2)
    plt.imshow(other_views, cmap='gray')
    plt.axis('off')
    plt.title('Saggital and Coronal views', fontsize=20)
    plt.show()
