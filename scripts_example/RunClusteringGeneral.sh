#!/bin/bash
#SBATCH --job-name=FSCS
#SBATCH --partition=savio
#SBATCH --open-mode=append

#####################################
### CUSTOMIZE THESE TWO VARIABLES ###
#####################################

# This is where you want to keep your FSCS scripts.
clusterPath="/global/scratch/groups/fc_flysong/scripts_example/"

# This should be the name of your .m script, which lives in $clusterPath
#   ...but exclude the .m extension.
matlabFilename="RunClusteringVirilisFSCSSpecNoise_MATT"


### Simplified batch analysis of .wav files with FlySongClusterSegment.
# There are only two arguments:
# - The full path to a .wav file to analyze.
# - The full path to a text file with all FlySongClusterSegment parameters.

# Usage: sbatch ./RunClusteringGeneral.sh <wavfile> <configfile>

# Parallel: Easiest option is to use QuickCluster.sh or ...
# Parallel: for f in /global/scratch/groups/fc_flysong/wav/2016-07-01*athabasca_x5*.wav; do sbatch ./RunClusteringGeneral.sh $f /global/scratch/[user]/x5/params.m; done
# Parallel: for f in `cat /global/scratch/[user]/x5/wavs.txt`; do sbatch ./RunClusteringGeneral.sh $f /global/scratch/[user]/x5/params.m; done

### Important note about batch processing:
# Moving all FlySongClusterSegment parameters into a single parameters file
#   assumes that a batch contains recordings of the same species, the same
#   hybrid, or the same hybrid group because several parameters in the config
#   file should be customized for the expected song characteristics.

echo "Running RunClusteringGeneral for $1 at `date`."
wavFile="$1" # Relative or absolute path for the .wav file.
parametersPath="$2" # This file contains all the parameters that were previously passed to the Matlab function.
cd "$clusterPath"
module load matlab
matlab -nodisplay -nosplash -nodesktop -r "$matlabFilename('$wavFile','$parametersPath'); exit"
echo "Finished running RunClusteringGeneral for $1 at `date`."
