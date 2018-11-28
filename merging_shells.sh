#preprocessing
module load MRtrix3/20180123 
module load FSL/5.0.11
module load ANTS/2.1.0

#The two shells of data are acquired as separate files, but need to be preprocessed together.  Use fslmerge to merge them.
parallel -j 30 "fslmerge -t /projects/janderson/PACTMD/pipelines/dwi/{}/ses-01/{}_merged.nii.gz /scratch/janderson/PACTMD_updated/{}/*CMH331000_run-01_dwi.nii.gz /scratch/janderson/PACTMD_updated/{}/*CMH333000_run-01_dwi.nii.gz" ::: `cat subs.txt` #first merge the two shells of data

#denoise the data using mrtrix
parallel -j 30 "dwidenoise /projects/janderson/PACTMD/pipelines/dwi/{}/ses-01/{}_merged.nii.gz /projects/janderson/PACTMD/pipelines/dwi/{}/ses-01/{}_merged_dn.nii.gz -force -noise /projects/janderson/PACTMD/pipelines/dwi/{}/ses-01/{}_noise.nii.gz" ::: `cat subs.txt` #then denoise them 

#now copy the bvals and bvecs files

for i in `cat subs.txt`
do

#copy the bvals
cp /projects/janderson/PACTMD/data/bids/${i}/ses-01/dwi/*CMH331000_run-01_dwi.bval /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_b1000.bval
cp /projects/janderson/PACTMD/data/bids/${i}/ses-01/dwi/*CMH333000_run-01_dwi.bval /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_b3000.bval
#copy the bvecs
cp /projects/janderson/PACTMD/data/bids/${i}/ses-01/dwi/*CMH331000_run-01_dwi.bvec /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_b1000.bvec
cp /projects/janderson/PACTMD/data/bids/${i}/ses-01/dwi/*CMH333000_run-01_dwi.bvec /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_b3000.bvec

#merge the bvals
paste -d" " /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/*b1000.bval /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/*b3000.bval > /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_merged.bval

#merge the bvecs
paste -d" " /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/*b1000.bvec /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/*b3000.bvec > /projects/janderson/PACTMD/pipelines/dwi/${i}/ses-01/${i}_merged.bvec
