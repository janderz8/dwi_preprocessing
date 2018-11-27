# dwi_preprocessing
This is the set of scripts that will be used to preprocess the NODDI data in the KIMEL lab for the PACTMD study.

Briefly, the steps we are including are:

##First script
1) reconstruct GE fieldmap
##Second Script
2) use dwidenoise (PCA based denoising) from the mrtrix package
3) run the updated version of EDDY (can handle higher b-values) using the fieldmap from step 1
4) run dwidebiascorrect from the mrtrix package
5) run the NODDI algorithm.  We will be using both the mdt toolbox https://mdt-toolbox.readthedocs.io/en/latest_release/ and the MATLAB script http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab to fit the NODDI parameters.
