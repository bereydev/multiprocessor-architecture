#!/bin/bash
#SBATCH --chdir /home/bereyzia/mularch/A3
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 28
#SBATCH --mem 10G

echo STARTING AT `date`

echo LOCAL
numactl -l ./numa

echo REMOTE
numactl -m 0 -N 1 ./numa

echo INTERLEAVED
numactl -i 0-1 ./numa

echo FINISHED at `date`
