#!/bin/bash
#SBATCH --chdir /scratch/bereyzia
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 16
#SBATCH --mem 2G
echo STARTING AT `date`
cd /home/bereyzia/mularch/A2

./heatmap 1 1000 500 output.csv
./heatmap 2 1000 500 output.csv
./heatmap 4 1000 500 output.csv
./heatmap 8 1000 500 output.csv
./heatmap 16 1000 500 output.csv



echo FINISHED at `date`
