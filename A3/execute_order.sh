#!/bin/bash
#SBATCH --chdir /home/delzio
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 28
#SBATCH --mem 10G
#SBATCH --partition serial
#SBATCH --account cs307
#SBATCH --reservation  CS307-CPU-3RD

echo STARTING AT `date`

echo SAME SOCKET
numactl --physcpubind=0,1,2 ./order

echo 2 SOCKETS
numactl --physcpubind=0,1,17 ./order


echo FINISHED at `date`
