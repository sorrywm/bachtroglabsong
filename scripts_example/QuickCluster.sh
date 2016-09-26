#!/bin/bash

# This script will analyze all .wav files listed in a .txt file.

################################
### CUSTOMIZE THIS VARIABLES ###
################################

# This is where you want to keep your FSCS scripts, and probably this script.
clusterPath="/global/scratch/groups/fc_flysong/scripts_example/"

# Requirements:
#  - The folder containing this script should also contain:
#    - RunClusteringGeneral.sh (has its own dependencies...see notes there)

# Input: Two plain text files.
#  - ($1) Path to a file that lists absolute paths to .wav files.
#  - ($2) Path to a parameters file (for RunClustering*.m script).

# Output: Dependent on parameters.
#  - Various results from RunClustering*.m script, including .mat files,
#     .fig files, and .txt files.

# Example:
#  ./QuickCluster.sh /global/scratch/[user]/x16/wavs.txt /global/scratch/[user]/x16/params.m


wavList="$1"
parametersPath="$2"
parametersLocation=$(dirname "${parametersPath}")

# If either input file does not exist, then exit.
if [ ! -e "$wavList" ]; then
    echo "The list of .wav files provided does not exist."
    exit
fi
if [ ! -e "$parametersPath" ]; then
    echo "The parameters file provided does not exist."
    exit
fi

groupScratchPath="/global/scratch/groups/fc_flysong"
wavPath="$groupScratchPath/wav"

# Switch to the analysis output folder (so slurm's .out files will go there).
cd $parametersLocation

# Execute the analysis script for each .wav file in the supplied list.
for f in `cat $wavList`; do sbatch "$clusterPath/RunClusteringGeneral.sh" $f $parametersPath; done

# Provide some feedback while you wait...
# The rest of this script can be deleted if you want to return to bash immediately.
sleep 5

# Every 10 seconds, check the jobs queue status.
# Wait until all your jobs are done before continuing.
### This looks for the sbatch job with the name 'FSCS' followed by the first 4
###   letters of your userIt should only find jobs executed from this script.
queueStatus=$(squeue | grep -P "FSCS.{1,8}${USER:0:4}")
while [ "$queueStatus" != "" ]; do
    echo $queueStatus;
    echo "still in queue or running...";
    sleep 10;
    queueStatus=$(squeue | grep -P "FSCS.{1,8}${USER:0:4}")
done
echo "done!"

