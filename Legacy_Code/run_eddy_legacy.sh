#!/bin/bash -l
k=$1

#go into each subjects directory & execute the following...
cd /projects/janderson/PACTMD/pipelines/dwi/${k}/ses-01/ #update path...

#dwidenoise ${k}_merged.nii.gz dMRI_denoise.nii.gz
mv ${k}_merged_dn.nii.gz dMRI_dn.nii.gz

fslroi dMRI_dn.nii.gz b0 0 1 #isolate the first b0
bet b0 nodif_brain -m -R -f 0.3 #skull strip b0
bet ${k}_magvolume.nii.gz Mag_bet -m -R -f 0.5 #skull strip magnitude image

#align the magnitude image to the b0 image (we will use the transform for the fieldmap)
flirt -dof 6 -in Mag_bet -ref nodif_brain -omat xformMagVol_to_diff.mat -out Mag_bet_diff
flirt -in ${k}_fieldmap_s -ref nodif_brain -applyxfm -init xformMagVol_to_diff.mat -out fieldmap_diff
fslmaths fieldmap_diff.nii.gz -abs -bin fieldmap_diff_bin.nii.gz # making for qc
fslmaths Mag_bet_diff.nii.gz -abs -bin Mag_bet_diff_bin.nii.gz # making for qc

vols=$(fslval dMRI_dn.nii.gz dim4) #pull number of volumes from dMRI header
indx=""
for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
echo $indx > index.txt

#Use the standard bval and bvec files that exist in each subjects folder.  Strange things happen to the bval files if you use them as is...
#cat *.bval > bval.txt #bval and bvec files need to be in txt file
#cat *.bvec > bvec.txt
#the code below should remove the double spacing
#cat *.bval | tr -s ' ' ' ' > bval.txt
#cat *.bvec | tr -s ' ' ' ' > bvec.txt


echo 0 1 0 0.013338  > acqparams.txt # # XX= echo spacing * number of phase encoding directions - 1 (it’s not that simple!)
# in my case I used [(40-1) * 0.000342] = 0.013338

#eddy - finally
eddy_openmp --imain=dMRI_dn.nii.gz --mask=nodif_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data --repol --residuals --cnr_maps -v
