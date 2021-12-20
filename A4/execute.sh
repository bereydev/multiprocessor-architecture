#!/bin/bash
#SBATCH --chdir /home/bereyzia/mularch/A4
#SBATCH --partition=gpu
#SBATCH --qos=gpu_free
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --time=1:0:0
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem 1G
#SBATCH --account cs307
#SBATCH --reservation CS307-GPU-WEEKLY

length=1000
iterations=10000

module load gcc cuda

echo STARTING AT `date`
make all
echo 100X100 10
./assignment4 100 10
echo 100X100 1_000
./assignment4 100 1000
echo 1_000X1_000 100
./assignment4 1000 100
echo 1_000X1_000 10_000
./assignment4 1000 10000
echo FINISHED at `date`
