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
 - Will start to detail the surface based approach here: based on the CIFTIFY algorithm by Erin Dickie
