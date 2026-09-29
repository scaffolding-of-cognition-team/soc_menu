#!/bin/bash
#
# Simulate realtime acquisition of MRI data by creating individual volumes and moving it to a folder that dicomFTP is looking at
# This is used in conjunction with Utils_realtime_nifti_viewer.py to test that it can render data well

# What is the volume you are going to read in
vol=$1

# Where is the folder that this is going to be moved to
outfolder=$2

# How long do we wait between TRs
TR_duration=$3

# Make the folder in case it doesn't exist
mkdir -p $outfolder

echo "Simulating realtime acquisition of MRI data by creating individual volumes and moving it to a folder that dicomFTP is looking at"
echo "What is the volume you are going to read in: $vol"
echo "Where is the folder that this is going to be moved to: $outfolder"
echo "How long do we wait between TRs: $TR_duration"

# Count the number of volumes
TR_num=`fslnvols $vol`

# Subtract 1 from the TR count
TR_num=`expr $TR_num - 1`

echo "Number of TRs: $TR_num"

for TR_counter in `seq 0 $TR_num`; do

    # Get the current volume
    volnum=`fslnvols $vol`

    # Make the file in this location temporarily
    fslroi $vol ./volume0001.nii.gz $TR_counter 1

    # Unzip the file
    gunzip ./volume0001.nii.gz

    # Move it to the other directory
    mv ./volume0001.nii $outfolder/volume0001.nii

    # If the volume is 0, then wait 1 second and try again
    sleep $TR_duration

done