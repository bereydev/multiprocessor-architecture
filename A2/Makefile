
CC = gcc
CFLAGS = -std=gnu99 -O3 -fopenmp -Wall

all: heatmap sharing

heatmap: heatmap.c utility.h algorithm2.c
	$(CC) $(CFLAGS) $< -o $@

sharing: sharing.c utility.h
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f heatmap sharing
