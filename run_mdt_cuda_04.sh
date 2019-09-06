#!/bin/bash -l
#SBATCH --partition=cudansha
#SBATCH --cpus-per-task=8
#SBATCH --array=1-285%5
#SBATCH --gres=gpu:titanx

#qm4k

sublist="`pwd`/subs.txt"

# Indicating subjects array
index_new() {
    head -n $SLURM_ARRAY_TASK_ID $sublist \
	| tail -n 1
}

source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load SGE-extras/1.0
module load cuda/7.5
module load MDT/0.18.2

cd /projects/janderson/PACTMD/pipelines/NODDI_mdt/pre_noddi/`index_new`/ #update path...

mdt-create-protocol bvec.txt bval.txt -o new.prtcl

mdt-model-fit 'Kurtosis' data.nii new.prtcl mask.nii
#note we could use NODDIDA or NODDI instead of the Kurtosis model in the above
