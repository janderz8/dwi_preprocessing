#!/usr/bin/env bash

module load FSL/5.0.10

for subject in `cat subs`
do

cd ${subject}

#split (pre) fieldmap files
fslsplit *Ax-FieldMapTE65-ASSET.nii.gz split65 -t
bet split650000 65mag -R -f 0.5 -m
fslmaths split650002 -mas 65mag_mask 65realm
fslmaths split650003 -mas 65mag_mask 65imagm

fslsplit *Ax-FieldMapTE85-ASSET.nii.gz split85 -t
bet split850000 85mag -R -f 0.5 -m
fslmaths split850002 -mas 85mag_mask 85realm
fslmaths split850003 -mas 85mag_mask 85imagm

#calc phase difference
fslmaths 65realm -mul 85realm realeq1
fslmaths 65imagm -mul 85imagm realeq2
fslmaths 65realm -mul 85imagm imageq1
fslmaths 85realm -mul 65imagm imageq2
fslmaths realeq1 -add realeq2 realvol
fslmaths imageq1 -sub imageq2 imagvol

#create complex image and extract phase and magnitude
fslcomplex -complex realvol imagvol calcomplex
fslcomplex -realphase calcomplex phasevolume 0 1
fslcomplex -realabs calcomplex magvolume 0 1

#unwrap phase
prelude -a 65mag -p phasevolume -m 65mag_mask -o phasevolume_maskUW

#divide by TE diff in seconds -> radians/sec
fslmaths phasevolume_maskUW -div 0.002 fieldmap_rads
fslmaths fieldmap_rads -div 6.28 fieldmap # fieldmap in Hz
#smooth the fieldmap (deals with the problem of non-invertability in eddy)
fslmaths fieldmap -kernel gauss 2 -fmean fieldmap_s


cp fieldmap_s.nii.gz /projects/janderson/PACTMD/pipelines/dwi/${subject}/ses-01/${subject}_fieldmap_s.nii.gz
cd ..
done
