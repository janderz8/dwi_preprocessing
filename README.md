# dwi_preprocessing & data preparation
This is the set of scripts that will be used to preprocess the NODDI data in the KIMEL lab for the PACTMD study.

Briefly, the steps we are including are:

**First Script** merging_shells_01.sh
1) use dwidenoise (PCA based denoising) from the mrtrix package
2) run the updated version of EDDY (can handle higher b-values) using the fieldmap from step 1
3) run dwidebiascorrect from the mrtrix package *this ended up not being included after all*

**Second script**
1) reconstruct GE fieldmap: mk_ge_fieldmap_02.sh
*note, in the future, I want to use  synthetic b0 or ANTs registration to correct distortion rather than fieldmaps which are unreliable*

**Third Script**
1) run FSL eddy's algorithm - see run_eddy_SLURM_03.sh

**Fourth Script**
1) run the NODDI algorithm.  We will be using both the mdt toolbox https://mdt-toolbox.readthedocs.io/en/latest_release/ to fit the NODDI parameters.
2) see the **run_mdt_cuda_04.sh** script to run the multishell estimation using NVIDIA cuda acceleration.  This is so much better than the base version from MATLAB - each person's data can be estimated in ~10 minutes instead of 30-40 minutes.



**Fifth Step (multiple scripts)**
1) The first approach is to use GBSS (https://github.com/arash-n/GBSS).  Note I had to alter this substantially to get it to work.  Here are my versions of Arash Nazeri's scripts (see GBSS folder)

**Sixth Step**
1) convert the data to surface space using CIFTIFY (Erin Dickie's work).  This can be run using the transform_NODDI_To_MNI_Surface_06.sh script.  The benefits of using surface based approches are a) we can now smooth the data without fear of smudging different tissue classes into one another (thus increasing power and accuracy), and b) unlike the GBSS algorithm, we can get a more continuous estimate of the entire surface without gaps using the midthickness values.  
![Figure 5 from Fukatomi et al., 2018](https://github.com/johnaeanderson/dwi_preprocessing/blob/master/Figures/Fukatomi_2018.jpg)
