#!/bin/bash
#SBATCH --chdir /scratch/bereyzia
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 4
#SBATCH --mem 2G

echo STARTING AT `date`

./sharing 4 100000000 32

./assignment2 4 10000 100 output.csv

echo FINISHED at `date`
