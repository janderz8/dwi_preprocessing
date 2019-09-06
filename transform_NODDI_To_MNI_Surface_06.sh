#!/bin/bash -l
#SBATCH --partition=low-moby
#SBATCH --cpus-per-task=4
#SBATCH --array=1-16%8

sublist="`pwd`/subs_for_transformation_continued.txt"

# Indicating subjects array
index_new() {
    head -n $SLURM_ARRAY_TASK_ID $sublist \
	| tail -n 1
}
echo "working on" sub-CMH`index_new`

source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load SGE-extras/1.0
#module load cuda/7.5
module load FSL/5.0.11
module load freesurfer/6.0.0
module load connectome-workbench/1.3.2
#first make the subject's diretory in the surface folder
mkdir /mnt/tigrlab/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`
#then copy the T1 image & the b0 file from each person to this surface folder...
cp /archive/data/PACTMD/pipelines/freesurfer-6.0.0/PACTMD_CMH_`index_new`_01/mri/brainmask.mgz /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`

cp /archive/data/PACTMD/pipelines/freesurfer-6.0.0/PACTMD_CMH_`index_new`_01/mri/T1.mgz /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`

#now go into each subject's folder, copy the processed DWI data to surface ...
cp /projects/janderson/PACTMD/pipelines/dwi/sub-CMH`index_new`/ses-01/data.nii.gz  /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`/DWI.nii.gz
#Copy the NODDI output from each subject's folder to the surface folder
cp /projects/janderson/PACTMD/pipelines/NODDI_mdt/post_noddi/sub-CMH`index_new`/NODDI/ODI.nii.gz  /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`
cp /projects/janderson/PACTMD/pipelines/NODDI_mdt/post_noddi/sub-CMH`index_new`/NODDI/NDI.nii.gz  /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`
cp /projects/janderson/PACTMD/pipelines/NODDI_mdt/post_noddi/sub-CMH`index_new`/NODDI/w_csf.w.nii.gz  /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`/CSF.nii.gz

##move into that subject's directory & keep going...
cd /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/sub-CMH`index_new`
#first convert the freesurfer brain mask into a nifti image...
mri_convert brainmask.mgz brainmask.nii
mri_convert T1.mgz brain.nii
fslreorient2s::td brainmask.nii brainmask_standard.nii.gz
fslreorient2std brain.nii brain_standard.nii.gz
#use BET to extract the b0's from the preprocessed DWI data
fslroi DWI.nii.gz b0 0 1
#remove the DWI image (not needed any longer)
rm DWI.nii.gz
bet b0 nodif_brain -m -R -f 0.3
#Also BET the T1 image
#bet T1.nii.gz T1_brain -m -R
bet brainmask_standard.nii.gz T1_brain -m -f 0
#now align the T1 to the MNI_152_2mm_brain image using an affine transform
flirt -in brainmask_standard.nii.gz -ref /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz -out T1_MNI_Affine.nii.gz -omat T1_MNI_Affine.mat
#now use a nonlinear transform (fnirt) to warp the T1 to the MNI space
fnirt --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --in=brainmask_standard.nii.gz --aff=T1_MNI_Affine.mat  --config=T1_2_MNI152_2mm --cout=T1_MNI_Nonlin --iout=T1_in_MNI_space
#now flirt the DWI image to the anatomical image using boundary based registration (BBR)
epi_reg --epi=nodif_brain.nii.gz --t1=brain_standard.nii.gz --t1brain=brainmask_standard.nii.gz --out=DWI_to_T1 -v
#now concatenate the transforms
convertwarp --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --warp1=T1_MNI_Nonlin.nii.gz --premat=DWI_to_T1.mat  --out=my_comprehensive_warps --relout
#apply the transforms to the relevant data
applywarp --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --in=NDI.nii.gz --warp=my_comprehensive_warps --rel  --out=NDI_in_MNI_space
applywarp --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --in=ODI.nii.gz --warp=my_comprehensive_warps --rel  --out=ODI_in_MNI_space
applywarp --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --in=CSF.nii.gz --warp=my_comprehensive_warps --rel  --out=CSF_in_MNI_space
applywarp --ref=/projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/MNI152_T1_2mm_brain.nii.gz --in=nodif_brain.nii.gz --warp=my_comprehensive_warps --rel --out=DWI_in_MNI_space


#now convert the data to surfaces using the ciftify tools ::: Continue from here...
for i in ODI NDI CSF
do
wb_command -volume-to-surface-mapping ${i}_in_MNI_space.nii.gz /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.midthickness.native.surf.gii sub-CMH`index_new`.L.${i}.native.shape.gii -ribbon-constrained /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.white.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.pial.native.surf.gii
#both hemispheres!
wb_command -volume-to-surface-mapping ${i}_in_MNI_space.nii.gz /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.midthickness.native.surf.gii sub-CMH`index_new`.R.${i}.native.shape.gii -ribbon-constrained /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.white.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.pial.native.surf.gii
done
# #
# # #-------------------------------------------------------------
# # #Making fMRI Ribbon
# # #-------------------------------------------------------------
# #
#/archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native

#first create signed distance volume for the white matter
wb_command -create-signed-distance-volume /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.white.native.surf.gii DWI_in_MNI_space.nii.gz L.white.native.nii.gz
#then create signed distance volume for the pial surface
wb_command -create-signed-distance-volume /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.pial.native.surf.gii DWI_in_MNI_space.nii.gz L.pial.native.nii.gz
#
#now use fslmaths to calculate the distance between the pial surface and white matter volumes
fslmaths L.white.native.nii.gz -thr 0 -bin -mul 255 L.white_thr0.native.nii.gz
fslmaths L.white_thr0.native.nii.gz -bin L.white_thr0.native.nii.gz
fslmaths L.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 L.pial_uthr0.native.nii.gz
fslmaths L.pial_uthr0.native.nii.gz -bin L.pial_uthr0.native.nii.gz
fslmaths L.pial_uthr0.native.nii.gz -mas L.white_thr0.native.nii.gz -mul 255 L.ribbon.nii.gz
fslmaths L.ribbon.nii.gz -bin -mul 1 L.ribbon.nii.gz
#
# #Now the right side...
#
wb_command -create-signed-distance-volume /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.white.native.surf.gii DWI_in_MNI_space.nii.gz R.white.native.nii.gz
wb_command -create-signed-distance-volume /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.pial.native.surf.gii DWI_in_MNI_space.nii.gz R.pial.native.nii.gz
fslmaths R.white.native.nii.gz -thr 0 -bin -mul 255 R.white_thr0.native.nii.gz
fslmaths R.white_thr0.native.nii.gz -bin R.white_thr0.native.nii.gz
fslmaths R.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 R.pial_uthr0.native.nii.gz
fslmaths R.pial_uthr0.native.nii.gz -bin R.pial_uthr0.native.nii.gz
fslmaths R.pial_uthr0.native.nii.gz -mas R.white_thr0.native.nii.gz -mul 255 R.ribbon.nii.gz
fslmaths R.ribbon.nii.gz -bin -mul 1 R.ribbon.nii.gz
fslmaths L.ribbon.nii.gz -add R.ribbon.nii.gz ribbon_only.nii.gz
# #
# # #-------------------------------------------------------------
# # #2018-11-04 16:08:28.081054 : Mapping fMRI to 32k Surface
# # #-------------------------------------------------------------
# # #Try with CSF first...
for i in ODI NDI CSF
do
# #
# #Make sure to change for cortex right !!!!!
wb_command -cifti-separate /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.thickness.native.dscalar.nii COLUMN -metric CORTEX_LEFT sub-CMH`index_new`.thickness.native.L.shape.gii

wb_command -volume-to-surface-mapping ${i}_in_MNI_space.nii.gz /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.midthickness.native.surf.gii sub-CMH`index_new`.L.${i}.myelin.native.shape.gii -myelin-style ribbon_only.nii.gz sub-CMH`index_new`.thickness.native.L.shape.gii 1

wb_command -metric-dilate sub-CMH`index_new`.L.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.midthickness.native.surf.gii 10 sub-CMH`index_new`.L.${i}.myelin.native.shape.gii -nearest

#mask, resample, mask,command
#MASK #1
wb_command -metric-mask sub-CMH`index_new`.L.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.roi.native.shape.gii sub-CMH`index_new`.L.${i}.myelin.native.shape.gii
#RESAMPLE
wb_command -metric-resample sub-CMH`index_new`.L.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.sphere.MSMSulc.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.L.sphere.32k_fs_LR.surf.gii ADAP_BARY_AREA sub-CMH`index_new`.L.${i}.myelin.32k_fs_LR.shape.gii -area-surfs /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.midthickness.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.L.midthickness.32k_fs_LR.surf.gii -current-roi /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.L.roi.native.shape.gii
#MASK #2
wb_command -metric-mask sub-CMH`index_new`.L.${i}.myelin.32k_fs_LR.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.L.atlasroi.32k_fs_LR.shape.gii sub-CMH`index_new`.L.${i}.myelin.32k_fs_LR.shape.gii

#Now the right side...

#Make sure to change for cortex right !!!!!
wb_command -cifti-separate /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.thickness.native.dscalar.nii COLUMN -metric CORTEX_RIGHT sub-CMH`index_new`.thickness.native.R.shape.gii

wb_command -volume-to-surface-mapping ${i}_in_MNI_space.nii.gz /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.midthickness.native.surf.gii sub-CMH`index_new`.R.${i}.myelin.native.shape.gii -myelin-style ribbon_only.nii.gz sub-CMH`index_new`.thickness.native.R.shape.gii 1

wb_command -metric-dilate sub-CMH`index_new`.R.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.midthickness.native.surf.gii 10 sub-CMH`index_new`.R.${i}.myelin.native.shape.gii -nearest

#mask, resample, mask,command
#MASK #1
wb_command -metric-mask sub-CMH`index_new`.R.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.roi.native.shape.gii sub-CMH`index_new`.R.${i}.myelin.native.shape.gii
#RESAMPLE
wb_command -metric-resample sub-CMH`index_new`.R.${i}.myelin.native.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.sphere.MSMSulc.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.R.sphere.32k_fs_LR.surf.gii ADAP_BARY_AREA sub-CMH`index_new`.R.${i}.myelin.32k_fs_LR.shape.gii -area-surfs /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.midthickness.native.surf.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.R.midthickness.32k_fs_LR.surf.gii -current-roi /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/Native/sub-CMH`index_new`.R.roi.native.shape.gii
#MASK #2
wb_command -metric-mask sub-CMH`index_new`.R.${i}.myelin.32k_fs_LR.shape.gii /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/fsaverage_LR32k/sub-CMH`index_new`.R.atlasroi.32k_fs_LR.shape.gii sub-CMH`index_new`.R.${i}.myelin.32k_fs_LR.shape.gii

wb_command -cifti-create-dense-scalar  ${i}_32K_combined.dscalar.nii -volume ${i}_in_MNI_space.nii.gz /archive/data/PACTMD/pipelines/bids_apps/ciftify/sub-CMH`index_new`/MNINonLinear/ROIs/Atlas_ROIs.2.nii.gz -left-metric sub-CMH`index_new`.L.${i}.myelin.32k_fs_LR.shape.gii -right-metric sub-CMH`index_new`.R.${i}.myelin.32k_fs_LR.shape.gii

#now to extract the values from the GLASSER atlas and write to csv files
 wb_command -cifti-parcellate ${i}_32K_combined.dscalar.nii /projects/janderson/PACTMD/pipelines/NODDI_mdt/surface/Glasser.dlabel.nii COLUMN ${i}_R_Glasser.pscalar.nii

wb_command -cifti-convert -to-text ${i}_R_Glasser.pscalar.nii ${i}_Glasser.csv

wb_command -cifti-convert -to-nifti ${i}_32K_combined.dscalar.nii ${i}_`index_new`_32K_combined.nii
wb_command -cifti-convert -to-nifti ${i}_R_Glasser.pscalar.nii ${i}_`index_new`_glasser_combined.nii

done
