#!/bin/bash -l
#SBATCH --partition=debug
#SBATCH --cpus-per-task=8
#SBATCH --array=1-262%20

sublist="`pwd`/subs_remainder.txt"

# Indicating subjects array
index_new() {
    head -n $SLURM_ARRAY_TASK_ID $sublist \
	| tail -n 1
}
echo "working on" `index_new`

source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load SGE-extras/1.0
#module load cuda/7.5
module load FSL/5.0.11


#go into each subjects directory & execute the following...
cd /projects/janderson/PACTMD/pipelines/dwi/`index_new`/ses-01/ #update path...
#first use MRtrix to denoise the data

#NOTE if we have already done denoising (as part of step 01, don't repeat)

dwidenoise `index`_merged.nii.gz dMRI_denoise.nii.gz
mv `index_new`_merged_dn.nii.gz dMRI_dn.nii.gz

fslroi dMRI_dn.nii.gz b0 0 1 #isolate the first b0
bet b0 nodif_brain -m -R -f 0.3 #skull strip b0
bet `index_new`_magvolume.nii.gz Mag_bet -m -R -f 0.5 #skull strip magnitude image

#NOTE it is probably preferable to use something like ANTS registration or the synthetic b0 with TOPUP to correct for image distortion in the dwi images.  Using the fieldmap images a) doesn't work that well, and b) only works if everyone has one (if they don't, we can't use that participant)

#align the magnitude image to the b0 image (we will use the transform for the fieldmap)
flirt -dof 6 -in Mag_bet -ref nodif_brain -omat xformMagVol_to_diff.mat -out Mag_bet_diff
flirt -in `index_new`_fieldmap_s -ref nodif_brain -applyxfm -init xformMagVol_to_diff.mat -out fieldmap_diff
fslmaths fieldmap_diff.nii.gz -abs -bin fieldmap_diff_bin.nii.gz # making for qc
fslmaths Mag_bet_diff.nii.gz -abs -bin Mag_bet_diff_bin.nii.gz # making for qc

vols=$(fslval dMRI_dn.nii.gz dim4) #pull number of volumes from dMRI header
indx=""
for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
echo $indx > index.txt

#Use the standard bval and bvec files that exist in each subjects folder.  Strange things happen to the bval files if you use them as is...
cat *.bval > bval.txt #bval and bvec files need to be in txt file
cat *.bvec > bvec.txt
the code below should remove the double spacing
cat *.bval | tr -s ' ' ' ' > bval.txt
cat *.bvec | tr -s ' ' ' ' > bvec.txt


echo 0 -1 0 0.013338  > acqparams.txt # # XX= echo spacing * number of phase encoding directions - 1 (it’s not that simple!)
# in my case I used [(40-1) * 0.000342] = 0.013338

#eddy - finally
echo "working on subject" `index_new`
eddy_openmp --imain=dMRI_dn.nii.gz --mask=nodif_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data --repol --residuals --cnr_maps -v
cat data.eddy_rotated_bvecs > eddy_bvecs.txt #need bvals and bvec in txt
fslroi data.nii.gz b0 0 1 #isolate first b0 from corrected data
bet b0 nodif_brain -m -R -f 0.3 #skull strip new b0

dtifit --data=data.nii.gz --mask=nodif_brain_mask --bvecs=eddy_bvecs.txt --bvals=bval.txt --out=dtifit --sse
